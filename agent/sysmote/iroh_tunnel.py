"""Túnel iroh: reenvía cada conexión entrante a un puerto TCP local.

Patrón dumbpipe. No depende de la API REST del agente ni la modifica:
cualquier servidor TCP local puede exponerse así.
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
# Puerto HTTP interno al que reenvía el túnel; solo debe escuchar en 127.0.0.1.
INTERNAL_HTTP_PORT = 8444
_CHUNK_SIZE = 64 * 1024
_RESET_CODE = 1
_REFUSED_CODE = 2
_EVICTED_CODE = 3
_ACCEPT_RETRY_DELAY = 1.0

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class Limits:
    max_connections: int = 4
    max_streams: int = 8
    idle_timeout: float = 60.0


# El bucle de eventos solo guarda referencias débiles a las tareas: sin una
# referencia propia, una tarea puede desaparecer a medio ejecutarse.
_tasks: set[asyncio.Task] = set()


def _spawn(coro) -> asyncio.Task:
    task = asyncio.create_task(coro)
    _tasks.add(task)
    task.add_done_callback(_tasks.discard)
    return task


def _load_or_create_secret_key(path: Path) -> iroh.SecretKey:
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
    pass


class _Activity:
    def __init__(self) -> None:
        self.last = time.monotonic()

    def touch(self) -> None:
        self.last = time.monotonic()


async def _pump_recv_to_writer(recv: iroh.RecvStream, writer: asyncio.StreamWriter, activity: _Activity) -> None:
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
    with contextlib.suppress(iroh.IrohError):
        await stream.send().reset(_REFUSED_CODE)
        await stream.recv().stop(_REFUSED_CODE)


async def _handle_connection(connection: iroh.Connection, local_port: int, limits: Limits = Limits()) -> None:
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
    try:
        await _handle_connection(connection, local_port, limits)
    finally:
        if connection in connections:
            connections.remove(connection)


async def _serve(endpoint: iroh.Endpoint, local_port: int, limits: Limits = Limits()) -> None:
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
    """Acepta conexiones iroh y las reenvía a `127.0.0.1:local_port`."""
    secret_key = _load_or_create_secret_key(secret_key_path)
    options = iroh.EndpointOptions(preset=iroh.preset_n0(), secret_key=secret_key.to_bytes(), alpns=[ALPN])
    endpoint = await iroh.Endpoint.bind(options)
    print(f"Túnel iroh activo. Identificador: {endpoint.id()}")
    try:
        await _serve(endpoint, local_port, limits)
    finally:
        await endpoint.close()
