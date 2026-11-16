"""Túnel iroh: reenvío real sobre QUIC en loopback.

No depende de red ni de relés: el cliente y el servidor iroh viven en el
mismo proceso y se conectan por sus direcciones directas.
"""

import asyncio

import iroh
import pytest
import uvicorn

from sysmote.iroh_tunnel import ALPN, _handle_connection, _tasks
from sysmote.main import app


@pytest.fixture
async def open_stream():
    """Abre un stream iroh hacia un túnel que reenvía a `127.0.0.1:local_port`."""
    endpoints = []
    tasks = []

    async def _open(local_port: int) -> iroh.BiStream:
        server = await iroh.Endpoint.bind(iroh.EndpointOptions(preset=iroh.preset_minimal(), alpns=[ALPN]))
        client = await iroh.Endpoint.bind(iroh.EndpointOptions(preset=iroh.preset_minimal()))
        endpoints.extend([server, client])

        async def accept() -> None:
            incoming = await server.accept_next()
            connection = await (await incoming.accept()).connect()
            await _handle_connection(connection, local_port)

        tasks.append(asyncio.create_task(accept()))
        connection = await client.connect(server.addr(), ALPN)
        return await connection.open_bi()

    yield _open
    for task in tasks:
        task.cancel()
    for endpoint in endpoints:
        await endpoint.close()


@pytest.fixture
async def running_agent():
    config = uvicorn.Config(app, host="127.0.0.1", port=0, log_level="warning")
    server = uvicorn.Server(config)
    server_task = asyncio.create_task(server.serve())
    while not server.started:
        await asyncio.sleep(0.01)
    yield server.servers[0].sockets[0].getsockname()[1]
    server.should_exit = True
    await server_task


async def test_tunnel_forwards_a_real_metrics_request(running_agent, open_stream):
    stream = await open_stream(running_agent)
    await stream.send().write_all(b"GET /metrics HTTP/1.1\r\nHost: sysmote\r\nConnection: close\r\n\r\n")
    await stream.send().finish()
    reply = await stream.recv().read_to_end(1_000_000)

    assert reply.startswith(b"HTTP/1.1 200 OK")
    assert b'"cpu_percent"' in reply


async def test_tunnel_resets_the_stream_when_the_local_agent_is_down(open_stream):
    stream = await open_stream(1)  # nada escucha en el puerto 1: el agente real está caído
    await stream.send().write_all(b"ping")
    await stream.send().finish()

    # Debe cerrarse enseguida (reset), no quedarse colgado hasta un timeout.
    with pytest.raises(iroh.IrohError):
        await asyncio.wait_for(stream.recv().read_to_end(1024), timeout=2)


async def test_tunnel_leaves_no_background_tasks_behind(running_agent, open_stream):
    # Con el agente en marcha y con el agente caído: cada petición lanza una tarea
    # de reenvío que debe desaparecer al terminar, no acumularse.
    for port in [running_agent] * 10 + [1] * 5:
        stream = await open_stream(port)
        await stream.send().write_all(b"GET /metrics HTTP/1.1\r\nHost: sysmote\r\nConnection: close\r\n\r\n")
        await stream.send().finish()
        try:
            await asyncio.wait_for(stream.recv().read_to_end(1_000_000), timeout=2)
        except iroh.IrohError:
            pass  # el reset del agente caído

    for _ in range(40):
        if not _tasks:
            break
        await asyncio.sleep(0.05)

    assert not _tasks
