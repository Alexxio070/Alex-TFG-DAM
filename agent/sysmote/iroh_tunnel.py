"""Túnel iroh: reenvía cada conexión entrante a un puerto TCP local.

Prueba de concepto de la fase 2 (patrón dumbpipe). No depende de la API REST
del agente ni la modifica: cualquier servidor TCP local puede exponerse así.
"""

import asyncio
import logging
import os
from pathlib import Path

import iroh

ALPN = b"sysmote/tunnel/0"
_CHUNK_SIZE = 64 * 1024

logger = logging.getLogger(__name__)

# El bucle de eventos solo guarda referencias débiles a las tareas: sin una
# referencia propia, una tarea puede desaparecer a medio ejecutarse.
_tasks: set[asyncio.Task] = set()


def _spawn(coro) -> None:
    task = asyncio.create_task(coro)
    _tasks.add(task)
    task.add_done_callback(_tasks.discard)


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


async def _pump_recv_to_writer(recv: iroh.RecvStream, writer: asyncio.StreamWriter) -> None:
    # No se propaga el EOF al socket local: uvicorn corta la respuesta si ve
    # medio cierre antes de contestar. Una petición HTTP ya es autocontenida
    # (cabeceras hasta `\r\n\r\n`), así que basta con dejar de escribir.
    while True:
        data = await recv.read(_CHUNK_SIZE)
        if not data:
            break
        writer.write(data)
        await writer.drain()


async def _pump_reader_to_send(reader: asyncio.StreamReader, send: iroh.SendStream) -> None:
    try:
        while True:
            data = await reader.read(_CHUNK_SIZE)
            if not data:
                break
            await send.write_all(data)
    finally:
        await send.finish()


async def _forward_stream(stream: iroh.BiStream, local_port: int) -> None:
    try:
        reader, writer = await asyncio.open_connection("127.0.0.1", local_port)
    except OSError:
        logger.warning("No se pudo conectar con el agente local en el puerto %d", local_port)
        await stream.send().reset(1)
        return
    try:
        await asyncio.gather(
            _pump_recv_to_writer(stream.recv(), writer),
            _pump_reader_to_send(reader, stream.send()),
        )
    except (iroh.IrohError, OSError):
        logger.warning("Conexión del túnel cortada antes de terminar el reenvío")
    finally:
        writer.close()


async def _handle_connection(connection: iroh.Connection, local_port: int) -> None:
    while True:
        try:
            stream = await connection.accept_bi()
        except iroh.IrohError:
            break
        _spawn(_forward_stream(stream, local_port))


async def run(local_port: int, secret_key_path: Path) -> None:
    """Acepta conexiones iroh y las reenvía a `127.0.0.1:local_port`."""
    secret_key = _load_or_create_secret_key(secret_key_path)
    options = iroh.EndpointOptions(preset=iroh.preset_n0(), secret_key=secret_key.to_bytes(), alpns=[ALPN])
    endpoint = await iroh.Endpoint.bind(options)
    print(f"Túnel iroh activo. Identificador: {endpoint.id()}")
    try:
        while (incoming := await endpoint.accept_next()) is not None:
            try:
                connection = await (await incoming.accept()).connect()
            except iroh.IrohError:
                # Un fallo en el saludo de una conexión no debe tumbar el túnel.
                logger.warning("Fallo al aceptar una conexión entrante; se sigue escuchando")
                continue
            _spawn(_handle_connection(connection, local_port))
    finally:
        await endpoint.close()
