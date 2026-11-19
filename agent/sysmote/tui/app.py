"""Aplicación Textual de la TUI `sysmote` y punto de entrada del comando `sysmote`.

El comando abre la TUI y arranca por debajo los servidores del agente (`server.py`); al salir
de la TUI se paran. La TUI lee y escribe en la misma base de datos SQLite que la API.
"""

import sqlite3
from datetime import UTC, datetime

from textual.app import App

from sysmote import database
from sysmote.tui.screens.main_screen import MainScreen
from sysmote.tui.widgets.formato import ETIQUETAS_SERVIDORES

ESPERA_AVISO_SEGUNDOS = 2


class SysmoteApp(App):
    """La TUI. Guarda el estado que comparten sus pestañas: la conexión, los servidores y el código de registro.

    Args:
        connection: conexión a SQLite; si no se pasa, abre la del agente y la cierra al salir.
        servidores: un `sysmote.server.Servidores` que arrancar y parar con la TUI, o `None` (tests).
    """

    TITLE = "Sysmote"

    def __init__(self, connection: sqlite3.Connection | None = None, servidores=None) -> None:
        super().__init__()
        self._cierra_su_conexion = connection is None
        self.connection = connection or database.connect()
        self.servidores = servidores
        # (código, caduca_en) del último código de registro generado; solo vive en memoria.
        self.registro_abierto: tuple[str, str] | None = None

    def on_mount(self) -> None:
        self.push_screen(MainScreen())
        if self.servidores is not None:
            self.servidores.iniciar()
            self.set_timer(ESPERA_AVISO_SEGUNDOS, self._avisar_errores)

    def on_unmount(self) -> None:
        if self.servidores is not None:
            self.servidores.detener()
        if self._cierra_su_conexion:
            self.connection.close()

    def codigo_registro_vigente(self) -> tuple[str, str] | None:
        """Devuelve el último código de registro y su caducidad si aún no ha caducado; si no, `None`."""
        if self.registro_abierto and self.registro_abierto[1] > datetime.now(UTC).isoformat():
            return self.registro_abierto
        return None

    def _avisar_errores(self) -> None:
        for nombre, estado in self.servidores.estado().items():
            if estado.startswith("error"):
                self.notify(
                    f"{ETIQUETAS_SERVIDORES[nombre]}: {estado}", severity="error", timeout=20
                )


def main() -> None:
    """Abre la TUI con los servidores del agente en marcha (comando `sysmote`)."""
    # Se importa aquí para que importar la TUI (por ejemplo, en los tests) no cargue los servidores.
    from sysmote.server import Servidores

    SysmoteApp(servidores=Servidores()).run()


if __name__ == "__main__":
    main()
