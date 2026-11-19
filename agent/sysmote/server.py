"""Servidores del agente: HTTPS para USB/LAN, HTTP interno para el túnel iroh y el túnel iroh.

Los tres sirven la misma app de FastAPI (`main.py`) y corren en un hilo aparte con su propio
bucle de eventos, para no bloquear la TUI ni quitarle el control de Ctrl+C. Por iroh no hace falta
TLS propio: iroh ya cifra la conexión y autentica al agente por su identificador.
"""

import asyncio
import threading

import uvicorn

from sysmote import iroh_tunnel, rutas
from sysmote.main import app
from sysmote.services import pairing_service, tls_service

PUERTO_INTERNO = 8444


class Servidores:
    """Arranca, para y vigila los servidores del agente.

    Crear el objeto genera el certificado TLS si falta, pero no abre ningún puerto: eso lo hace
    `iniciar()`. Si un servidor falla (por ejemplo, un puerto ocupado) los demás siguen.

    Args:
        puerto_https: puerto del HTTPS, que escucha en todas las interfaces (USB y red local).
        puerto_interno: puerto del HTTP interno, solo en `127.0.0.1`; el túnel iroh reenvía aquí.
        con_iroh: si arrancar también el túnel iroh (los tests lo desactivan).
    """

    def __init__(
        self,
        puerto_https: int = pairing_service.PUERTO_HTTPS,
        puerto_interno: int = PUERTO_INTERNO,
        con_iroh: bool = True,
    ) -> None:
        cert, clave = tls_service.asegurar_certificado()
        self._puerto_interno = puerto_interno
        self._con_iroh = con_iroh
        self._https = uvicorn.Server(
            uvicorn.Config(
                app, host="0.0.0.0", port=puerto_https, ssl_certfile=str(cert), ssl_keyfile=str(clave),
                log_config=None, access_log=False, timeout_graceful_shutdown=2,
            )
        )
        self._interno = uvicorn.Server(
            uvicorn.Config(
                app, host="127.0.0.1", port=puerto_interno,
                log_config=None, access_log=False, timeout_graceful_shutdown=2,
            )
        )
        self._errores: dict[str, str] = {}
        self._iroh_vivo = False
        self._hilo: threading.Thread | None = None
        self._bucle: asyncio.AbstractEventLoop | None = None
        self._parar: asyncio.Event | None = None

    def iniciar(self) -> None:
        """Arranca los servidores en un hilo aparte y vuelve enseguida."""
        self._hilo = threading.Thread(target=lambda: asyncio.run(self._servir()), daemon=True)
        self._hilo.start()

    def detener(self) -> None:
        """Para los servidores y espera a que el hilo termine (como mucho 5 segundos)."""
        if self._hilo is None:
            return
        if self._bucle is not None and self._parar is not None:
            self._bucle.call_soon_threadsafe(self._parar.set)
        self._hilo.join(timeout=5)

    def estado(self) -> dict[str, str]:
        """Devuelve el estado de cada servidor para mostrarlo en la TUI.

        Valores: `arrancando`, `activo` o `error: …`. Para iroh, `en marcha` significa que la tarea
        del túnel está viva, no que se haya confirmado la conexión con la red de iroh.
        """
        resultado = {
            "https": self._estado_uvicorn("https", self._https),
            "interno": self._estado_uvicorn("interno", self._interno),
        }
        if self._con_iroh:
            resultado["iroh"] = self._errores.get("iroh") or ("en marcha" if self._iroh_vivo else "arrancando")
        return resultado

    def _estado_uvicorn(self, nombre: str, servidor: uvicorn.Server) -> str:
        return self._errores.get(nombre) or ("activo" if servidor.started else "arrancando")

    async def _servir(self) -> None:
        self._bucle = asyncio.get_running_loop()
        self._parar = asyncio.Event()
        tareas = [
            asyncio.create_task(self._ejecutar("https", self._https.serve())),
            asyncio.create_task(self._ejecutar("interno", self._interno.serve())),
        ]
        if self._con_iroh:
            tunel = asyncio.create_task(self._ejecutar("iroh", self._tunel()))
            tareas.append(tunel)
        await self._parar.wait()
        self._https.should_exit = True
        self._interno.should_exit = True
        if self._con_iroh:
            tunel.cancel()
        await asyncio.gather(*tareas, return_exceptions=True)

    async def _tunel(self) -> None:
        self._iroh_vivo = True
        try:
            await iroh_tunnel.run(self._puerto_interno, rutas.IROH_KEY_PATH)
        finally:
            self._iroh_vivo = False

    async def _ejecutar(self, nombre: str, corrutina) -> None:
        try:
            await corrutina
        except asyncio.CancelledError:
            raise
        except SystemExit:
            self._errores[nombre] = "error: no se pudo abrir el puerto (¿ya está en uso?)"
        except Exception as error:
            self._errores[nombre] = f"error: {error}"
