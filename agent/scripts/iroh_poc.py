"""Arranca el agente real y el túnel iroh para la prueba de concepto de la fase 2.

Uso:
    .venv/bin/python scripts/iroh_poc.py

Imprime el identificador iroh del agente. Pégalo en Ajustes de la app (modo
iroh) para ver las métricas a través del túnel.
"""

import asyncio
from pathlib import Path

import uvicorn

from sysmote.iroh_tunnel import run as run_tunnel
from sysmote.main import app

LOCAL_PORT = 8443
SECRET_KEY_PATH = Path.home() / ".local" / "share" / "sysmote" / "iroh_secret_key_poc.bin"


async def main() -> None:
    config = uvicorn.Config(app, host="127.0.0.1", port=LOCAL_PORT, log_level="warning")
    server = uvicorn.Server(config)
    server_task = asyncio.create_task(server.serve())
    while not server.started:
        await asyncio.sleep(0.05)

    try:
        await run_tunnel(LOCAL_PORT, SECRET_KEY_PATH)
    finally:
        server.should_exit = True
        await server_task


if __name__ == "__main__":
    asyncio.run(main())
