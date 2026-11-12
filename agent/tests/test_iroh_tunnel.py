"""Prueba de concepto del túnel iroh: reenvío real sobre un socket QUIC local.

No depende de red ni de relés: el cliente y el servidor iroh viven en el
mismo proceso y se conectan por sus direcciones directas en loopback.
"""

import asyncio

import iroh
import pytest
import uvicorn

from sysmote.iroh_tunnel import ALPN, _handle_connection
from sysmote.main import app


@pytest.fixture
async def echo_server():
    async def handle(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        data = await reader.read(1024)
        writer.write(data)
        await writer.drain()
        writer.close()

    server = await asyncio.start_server(handle, "127.0.0.1", 0)
    port = server.sockets[0].getsockname()[1]
    yield port
    server.close()
    await server.wait_closed()


async def test_tunnel_forwards_bytes_to_local_server(echo_server):
    local_port = echo_server

    server_options = iroh.EndpointOptions(preset=iroh.preset_minimal(), alpns=[ALPN])
    server_endpoint = await iroh.Endpoint.bind(server_options)

    async def accept_loop():
        incoming = await server_endpoint.accept_next()
        accepting = await incoming.accept()
        connection = await accepting.connect()
        await _handle_connection(connection, local_port)

    accept_task = asyncio.create_task(accept_loop())

    client_options = iroh.EndpointOptions(preset=iroh.preset_minimal())
    client_endpoint = await iroh.Endpoint.bind(client_options)
    connection = await client_endpoint.connect(server_endpoint.addr(), ALPN)

    stream = await connection.open_bi()
    await stream.send().write_all(b"ping")
    await stream.send().finish()
    reply = await stream.recv().read_to_end(1024)

    assert reply == b"ping"

    accept_task.cancel()
    await client_endpoint.close()
    await server_endpoint.close()


async def test_tunnel_resets_the_stream_when_the_local_agent_is_down():
    unused_port = 1  # nada escucha ahí: simula el agente real caído

    server_options = iroh.EndpointOptions(preset=iroh.preset_minimal(), alpns=[ALPN])
    server_endpoint = await iroh.Endpoint.bind(server_options)

    async def accept_loop():
        incoming = await server_endpoint.accept_next()
        accepting = await incoming.accept()
        connection = await accepting.connect()
        await _handle_connection(connection, unused_port)

    accept_task = asyncio.create_task(accept_loop())

    client_options = iroh.EndpointOptions(preset=iroh.preset_minimal())
    client_endpoint = await iroh.Endpoint.bind(client_options)
    connection = await client_endpoint.connect(server_endpoint.addr(), ALPN)

    stream = await connection.open_bi()
    await stream.send().write_all(b"ping")
    await stream.send().finish()

    # Debe cerrarse enseguida (reset), no quedarse colgado hasta un timeout.
    with pytest.raises(iroh.IrohError):
        await asyncio.wait_for(stream.recv().read_to_end(1024), timeout=2)

    accept_task.cancel()
    await client_endpoint.close()
    await server_endpoint.close()


@pytest.fixture
async def running_agent():
    config = uvicorn.Config(app, host="127.0.0.1", port=0, log_level="warning")
    server = uvicorn.Server(config)
    server_task = asyncio.create_task(server.serve())
    while not server.started:
        await asyncio.sleep(0.01)
    port = server.servers[0].sockets[0].getsockname()[1]
    yield port
    server.should_exit = True
    await server_task


async def test_tunnel_forwards_a_real_metrics_request(running_agent):
    local_port = running_agent

    server_options = iroh.EndpointOptions(preset=iroh.preset_minimal(), alpns=[ALPN])
    server_endpoint = await iroh.Endpoint.bind(server_options)

    async def accept_loop():
        incoming = await server_endpoint.accept_next()
        accepting = await incoming.accept()
        connection = await accepting.connect()
        await _handle_connection(connection, local_port)

    accept_task = asyncio.create_task(accept_loop())

    client_options = iroh.EndpointOptions(preset=iroh.preset_minimal())
    client_endpoint = await iroh.Endpoint.bind(client_options)
    connection = await client_endpoint.connect(server_endpoint.addr(), ALPN)

    stream = await connection.open_bi()
    await stream.send().write_all(b"GET /metrics HTTP/1.1\r\nHost: sysmote\r\nConnection: close\r\n\r\n")
    await stream.send().finish()
    reply = await stream.recv().read_to_end(1_000_000)

    assert reply.startswith(b"HTTP/1.1 200 OK")
    assert b'"cpu_percent"' in reply

    accept_task.cancel()
    await client_endpoint.close()
    await server_endpoint.close()
