"""Túnel iroh del agente: deja usar la API desde fuera de casa sin abrir puertos.

Acepta conexiones iroh y reenvía cada *stream* al puerto HTTP interno del agente,
que solo escucha en `127.0.0.1`, sin mirar los bytes (patrón *dumbpipe*): la API
no distingue si la petición llegó por iroh o por la red local. Lo arranca
`sysmote.server.Servidores`. Detalle en `doc/iroh/02-implementacion.md`.
"""

import asyncio
import contextlib
import logging
import os
import time
from dataclasses import dataclass
from pathlib import Path

import iroh

ALPN = b"sysmote/tunnel/0"
"""Protocolo del túnel: la app lo pide al conectar."""

_CHUNK_SIZE = 64 * 1024
_RESET_CODE = 1
_REFUSED_CODE = 2
_EVICTED_CODE = 3
_ACCEPT_RETRY_DELAY = 1.0

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class Limits:
    """Límites del túnel frente a un cliente que abuse de él.

    Attributes:
        max_connections: conexiones simultáneas; al superarlo se cierra la más antigua.
        max_streams: *streams* simultáneos por conexión; los sobrantes se rechazan.
        idle_timeout: segundos sin datos en ningún sentido antes de cortar un *stream*.
    """

    max_connections: int = 4
    max_streams: int = 8
    idle_timeout: float = 60.0


# El bucle de eventos solo guarda referencias débiles a las tareas: sin una
# referencia propia, una tarea puede desaparecer a medio ejecutarse.
_tasks: set[asyncio.Task] = set()


def _spawn(coro) -> asyncio.Task:
    """Lanza una tarea en segundo plano y guarda una referencia hasta que termina."""
    task = asyncio.create_task(coro)
    _tasks.add(task)
    task.add_done_callback(_tasks.discard)
    return task


def load_or_create_secret_key(path: Path) -> iroh.SecretKey:
    """Carga la clave secreta del agente, o la crea si todavía no existe.

    La clave fija el identificador iroh: guardarla en disco hace que el
    identificador sobreviva a los reinicios.

    Args:
        path: archivo de la clave. Si se crea, nace con permisos `0600`.

    Returns:
        La clave secreta.

    Raises:
        ValueError: si el archivo existe pero no contiene una clave válida.
    """
    if path.exists():
        try:
            return iroh.SecretKey.from_bytes(path.read_bytes())
        except iroh.IrohError as error:
            raise ValueError(f"La clave secreta {path} no es válida: bórrala para generar otra") from error
    secret_key = iroh.SecretKey.generate()
    path.parent.mkdir(parents=True, exist_ok=True)
    # Con 0o600 desde la creación: escribir primero y hacer chmod después deja
    # el archivo legible por otros usuarios durante unos instantes.
    with os.fdopen(os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "wb") as file:
        file.write(secret_key.to_bytes())
    return secret_key


class _IdleTimeout(Exception):
    """Un *stream* ha pasado `idle_timeout` sin mover datos."""


class _Activity:
    """Momento del último dato movido en cualquiera de los dos sentidos de un *stream*."""

    def __init__(self) -> None:
        self.last = time.monotonic()

    def touch(self) -> None:
        self.last = time.monotonic()


async def _pump_recv_to_writer(recv: iroh.RecvStream, writer: asyncio.StreamWriter, activity: _Activity) -> None:
    """Copia lo que llega por iroh al socket local."""
    # No se propaga el EOF al socket local: uvicorn corta la respuesta si ve
    # medio cierre antes de contestar. Una petición HTTP ya es autocontenida
    # (cabeceras hasta `\r\n\r\n`), así que basta con dejar de escribir.
    while True:
        data = await recv.read(_CHUNK_SIZE)
        if not data:
            break
        activity.touch()
        writer.write(data)
        await writer.drain()


async def _pump_reader_to_send(reader: asyncio.StreamReader, send: iroh.SendStream, activity: _Activity) -> None:
    """Copia la respuesta del socket local al *stream* de iroh y lo cierra al terminar."""
    try:
        while True:
            data = await reader.read(_CHUNK_SIZE)
            if not data:
                break
            activity.touch()
            await send.write_all(data)
    finally:
        await send.finish()


async def _wait_unless_idle(work: asyncio.Future, activity: _Activity, idle_timeout: float) -> None:
    """Espera a `work`; si ninguna dirección mueve datos durante `idle_timeout`, lo cancela."""
    while not work.done():
        remaining = idle_timeout - (time.monotonic() - activity.last)
        if remaining <= 0:
            work.cancel()
            raise _IdleTimeout
        await asyncio.wait({work}, timeout=remaining)
    work.result()


async def _forward_stream(stream: iroh.BiStream, local_port: int, idle_timeout: float) -> None:
    """Reenvía un *stream* al puerto local en los dos sentidos hasta que termina, falla o se queda inactivo."""
    try:
        reader, writer = await asyncio.open_connection("127.0.0.1", local_port)
    except OSError:
        logger.warning("No se pudo conectar con el agente local en el puerto %d", local_port)
        await stream.send().reset(_RESET_CODE)
        return
    activity = _Activity()
    pumps = asyncio.gather(
        _pump_recv_to_writer(stream.recv(), writer, activity),
        _pump_reader_to_send(reader, stream.send(), activity),
    )
    try:
        await _wait_unless_idle(pumps, activity, idle_timeout)
    except _IdleTimeout:
        logger.warning("Stream del túnel sin actividad durante %s s; se corta", idle_timeout)
        with contextlib.suppress(iroh.IrohError):
            await stream.send().reset(_RESET_CODE)
    except (iroh.IrohError, OSError):
        logger.warning("Conexión del túnel cortada antes de terminar el reenvío")
    finally:
        writer.close()


async def _refuse_stream(stream: iroh.BiStream) -> None:
    """Rechaza un *stream* sobrante cortándolo en los dos sentidos."""
    with contextlib.suppress(iroh.IrohError):
        await stream.send().reset(_REFUSED_CODE)
        await stream.recv().stop(_REFUSED_CODE)


async def _handle_connection(connection: iroh.Connection, local_port: int, limits: Limits) -> None:
    """Atiende los *streams* de una conexión, como mucho `limits.max_streams` a la vez."""
    active = 0

    def release(_task: asyncio.Task) -> None:
        nonlocal active
        active -= 1

    while True:
        try:
            stream = await connection.accept_bi()
        except iroh.IrohError:
            break
        if active >= limits.max_streams:
            logger.warning("Demasiados streams simultáneos en una conexión; se rechaza uno")
            await _refuse_stream(stream)
            continue
        active += 1
        _spawn(_forward_stream(stream, local_port, limits.idle_timeout)).add_done_callback(release)


async def _handle_tracked_connection(
    connection: iroh.Connection, local_port: int, limits: Limits, connections: list[iroh.Connection]
) -> None:
    """Atiende una conexión y la quita de la lista de activas cuando termina."""
    try:
        await _handle_connection(connection, local_port, limits)
    finally:
        if connection in connections:
            connections.remove(connection)


async def _serve(endpoint: iroh.Endpoint, local_port: int, limits: Limits = Limits()) -> None:
    """Bucle de aceptación: un fallo con una conexión se registra y no tumba el túnel."""
    connections: list[iroh.Connection] = []
    while True:
        try:
            incoming = await endpoint.accept_next()
        except Exception:
            logger.exception("Error al esperar conexiones; se reintenta")
            if endpoint.is_closed():
                break
            await asyncio.sleep(_ACCEPT_RETRY_DELAY)
            continue
        if incoming is None:
            break
        try:
            connection = await (await incoming.accept()).connect()
        except iroh.IrohError:
            # Un fallo en el saludo de una conexión no debe tumbar el túnel.
            logger.warning("Fallo al aceptar una conexión entrante; se sigue escuchando")
            continue
        except Exception:
            logger.exception("Error inesperado al aceptar una conexión; se sigue escuchando")
            continue
        connections.append(connection)
        if len(connections) > limits.max_connections:
            logger.warning("Demasiadas conexiones simultáneas; se cierra la más antigua")
            connections.pop(0).close(_EVICTED_CODE, b"too many connections")
        _spawn(_handle_tracked_connection(connection, local_port, limits, connections))


async def run(local_port: int, secret_key_path: Path, limits: Limits = Limits()) -> None:
    """Arranca el túnel y lo mantiene hasta que se cancela.

    Args:
        local_port: puerto HTTP interno del agente, que solo escucha en `127.0.0.1`.
        secret_key_path: archivo de la clave secreta, que fija el identificador iroh.
        limits: límites frente a abusos (ver `Limits`).
    """
    secret_key = load_or_create_secret_key(secret_key_path)
    options = iroh.EndpointOptions(preset=iroh.preset_n0(), secret_key=secret_key.to_bytes(), alpns=[ALPN])
    endpoint = await iroh.Endpoint.bind(options)
    print(f"Túnel iroh activo. Identificador: {endpoint.id()}")
    try:
        await _serve(endpoint, local_port, limits)
    finally:
        await endpoint.close()
