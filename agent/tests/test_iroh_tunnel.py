"""Túnel iroh: reenvío real sobre QUIC en loopback.

No depende de red ni de relés: el cliente y el servidor iroh viven en el
mismo proceso y se conectan por sus direcciones directas.
"""

import asyncio

import iroh
import pytest
import uvicorn

from sysmote.iroh_tunnel import ALPN, Limits, _handle_connection, _serve, _tasks
from sysmote.main import app

_METRICS_REQUEST = b"GET /metrics HTTP/1.1\r\nHost: sysmote\r\nConnection: close\r\n\r\n"


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
    await stream.send().write_all(_METRICS_REQUEST)
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
        await stream.send().write_all(_METRICS_REQUEST)
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


class _Lab:
    """Endpoints iroh locales para probar `_serve`, cerrados al terminar el test."""

    def __init__(self) -> None:
        self.endpoints: list[iroh.Endpoint] = []
        self.tasks: list[asyncio.Task] = []

    async def server(self) -> iroh.Endpoint:
        endpoint = await iroh.Endpoint.bind(iroh.EndpointOptions(preset=iroh.preset_minimal(), alpns=[ALPN]))
        self.endpoints.append(endpoint)
        return endpoint

    async def connect(self, server: iroh.Endpoint) -> iroh.Connection:
        client = await iroh.Endpoint.bind(iroh.EndpointOptions(preset=iroh.preset_minimal()))
        self.endpoints.append(client)
        return await client.connect(server.addr(), ALPN)

    def serve(self, endpoint, local_port: int, limits: Limits = Limits()) -> None:
        self.tasks.append(asyncio.create_task(_serve(endpoint, local_port, limits)))

    async def close(self) -> None:
        for task in self.tasks:
            task.cancel()
        for endpoint in self.endpoints:
            await endpoint.close()


@pytest.fixture
async def lab():
    lab = _Lab()
    yield lab
    await lab.close()


@pytest.fixture
async def start_local_server():
    """Arranca un servidor TCP local con el comportamiento que se le pase."""
    servers = []

    async def _start(handler) -> int:
        server = await asyncio.start_server(handler, "127.0.0.1", 0)
        servers.append(server)
        return server.sockets[0].getsockname()[1]

    yield _start
    for server in servers:
        server.close()


async def _silent(reader, writer):
    try:
        await reader.read()
    finally:
        writer.close()


async def _trickle(reader, writer):
    # Responde un byte cada 0,1 s durante 0,8 s: tarda más que el límite de inactividad
    # de los tests, pero nunca está parado.
    try:
        await reader.read(1)
        for _ in range(8):
            writer.write(b"x")
            await writer.drain()
            await asyncio.sleep(0.1)
    finally:
        writer.close()


async def _get_metrics(connection: iroh.Connection) -> bytes:
    stream = await connection.open_bi()
    await stream.send().write_all(_METRICS_REQUEST)
    await stream.send().finish()
    return await asyncio.wait_for(stream.recv().read_to_end(1_000_000), timeout=5)


async def test_tunnel_closes_the_oldest_connection_beyond_the_limit(lab, running_agent):
    server = await lab.server()
    lab.serve(server, running_agent, Limits(max_connections=2))
    first = await lab.connect(server)
    second = await lab.connect(server)
    third = await lab.connect(server)

    for _ in range(40):
        if first.close_reason():
            break
        await asyncio.sleep(0.05)

    assert "too many connections" in str(first.close_reason())
    assert (await _get_metrics(second)).startswith(b"HTTP/1.1 200 OK")
    assert (await _get_metrics(third)).startswith(b"HTTP/1.1 200 OK")


async def test_tunnel_refuses_streams_beyond_the_limit(lab, start_local_server):
    port = await start_local_server(_silent)
    server = await lab.server()
    lab.serve(server, port, Limits(max_streams=2))
    connection = await lab.connect(server)

    streams = []
    for _ in range(3):
        stream = await connection.open_bi()
        await stream.send().write_all(b"x")
        streams.append(stream)
        await asyncio.sleep(0.2)

    with pytest.raises(iroh.IrohError):
        await asyncio.wait_for(streams[2].recv().read_to_end(1024), timeout=3)
    with pytest.raises(asyncio.TimeoutError):
        await asyncio.wait_for(streams[0].recv().read_to_end(1024), timeout=0.3)


async def test_tunnel_frees_a_stream_slot_when_the_stream_ends(lab, running_agent):
    server = await lab.server()
    lab.serve(server, running_agent, Limits(max_streams=2))
    connection = await lab.connect(server)

    for _ in range(10):
        assert (await _get_metrics(connection)).startswith(b"HTTP/1.1 200 OK")


async def test_tunnel_resets_a_stream_that_stays_idle(lab, start_local_server):
    port = await start_local_server(_silent)
    server = await lab.server()
    lab.serve(server, port, Limits(idle_timeout=0.3))
    connection = await lab.connect(server)

    stream = await connection.open_bi()
    await stream.send().write_all(b"x")

    with pytest.raises(iroh.IrohError):
        await asyncio.wait_for(stream.recv().read_to_end(1024), timeout=3)


async def test_tunnel_keeps_a_stream_that_keeps_moving_data(lab, start_local_server):
    port = await start_local_server(_trickle)
    server = await lab.server()
    lab.serve(server, port, Limits(idle_timeout=0.3))
    connection = await lab.connect(server)

    stream = await connection.open_bi()
    await stream.send().write_all(b"go")
    await stream.send().finish()

    assert await asyncio.wait_for(stream.recv().read_to_end(1024), timeout=5) == b"x" * 8


class _FlakyEndpoint:
    """Envuelve un Endpoint real y falla una vez, como `accept_next` o al aceptar."""

    def __init__(self, real: iroh.Endpoint, fail_on_accept: bool) -> None:
        self._real = real
        self._fail_on_accept = fail_on_accept
        self._calls = 0

    async def accept_next(self):
        self._calls += 1
        if self._calls == 1:
            if not self._fail_on_accept:
                raise RuntimeError("fallo inesperado")
            return _BrokenIncoming()
        return await self._real.accept_next()

    def is_closed(self) -> bool:
        return self._real.is_closed()


class _BrokenIncoming:
    async def accept(self):
        raise RuntimeError("fallo inesperado")


@pytest.mark.parametrize("fail_on_accept", [False, True], ids=["al esperar", "al aceptar"])
async def test_tunnel_keeps_serving_after_an_unexpected_error(
    fail_on_accept, lab, running_agent, monkeypatch, caplog
):
    monkeypatch.setattr("sysmote.iroh_tunnel._ACCEPT_RETRY_DELAY", 0.01)
    server = await lab.server()
    lab.serve(_FlakyEndpoint(server, fail_on_accept), running_agent)

    connection = await lab.connect(server)

    assert (await _get_metrics(connection)).startswith(b"HTTP/1.1 200 OK")
    assert "inesperado" in caplog.text
