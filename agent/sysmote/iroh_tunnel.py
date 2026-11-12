"""Túnel iroh: reenvía cada conexión entrante a un puerto TCP local.

Prueba de concepto de la fase 2 (patrón dumbpipe). No depende de la API REST
del agente ni la modifica: cualquier servidor TCP local puede exponerse así.
"""

import asyncio
import logging
from pathlib import Path

import iroh

ALPN = b"sysmote/tunnel/0"
_CHUNK_SIZE = 64 * 1024

logger = logging.getLogger(__name__)


def _load_or_create_secret_key(path: Path) -> iroh.SecretKey:
    if path.exists():
        return iroh.SecretKey.from_bytes(path.read_bytes())
    secret_key = iroh.SecretKey.generate()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(secret_key.to_bytes())
    path.chmod(0o600)
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


async def _watch_path(connection: iroh.Connection) -> None:
    """Diagnóstico de la prueba 1 de la matriz: imprime si la conexión va
    por el relé o directa, y avisa cuando cambia de una a otra."""
    last_is_relay = None
    while True:
        try:
            paths = connection.paths()
        except iroh.IrohError:
            break
        selected = next((p for p in paths if p.is_selected), None)
        if selected is not None and selected.is_relay != last_is_relay:
            last_is_relay = selected.is_relay
            via = "RELÉ" if selected.is_relay else "DIRECTA"
            print(f"[ruta] conexión {via} ({selected.remote_addr}, rtt={selected.rtt_ms} ms)")
        await asyncio.sleep(2)


async def _handle_connection(connection: iroh.Connection, local_port: int) -> None:
    asyncio.create_task(_watch_path(connection))
    while True:
        try:
            stream = await connection.accept_bi()
        except iroh.IrohError:
            break
        asyncio.create_task(_forward_stream(stream, local_port))


async def _accept_one(endpoint: iroh.Endpoint, local_port: int) -> bool:
    """Acepta la siguiente conexión entrante. Devuelve False si el endpoint se cerró."""
    incoming = await endpoint.accept_next()
    if incoming is None:
        return False
    try:
        accepting = await incoming.accept()
        connection = await accepting.connect()
    except iroh.IrohError:
        logger.warning("Fallo al aceptar una conexión entrante; se ignora y se sigue escuchando")
        return True
    asyncio.create_task(_handle_connection(connection, local_port))
    return True


async def run(local_port: int, secret_key_path: Path) -> None:
    """Acepta conexiones iroh y las reenvía a `127.0.0.1:local_port`."""
    secret_key = _load_or_create_secret_key(secret_key_path)
    options = iroh.EndpointOptions(preset=iroh.preset_n0(), secret_key=secret_key.to_bytes(), alpns=[ALPN])
    endpoint = await iroh.Endpoint.bind(options)
    print(f"Túnel iroh activo. Identificador: {endpoint.id()}")
    try:
        while await _accept_one(endpoint, local_port):
            pass
    finally:
        await endpoint.close()
