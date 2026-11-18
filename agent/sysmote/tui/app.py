"""Sysmote: interfaz de terminal (TUI) con Textual."""

import sqlite3
from datetime import UTC, datetime

from textual.app import App

from sysmote import database
from sysmote.tui.screens.main_screen import MainScreen
from sysmote.tui.widgets.formato import ETIQUETAS_SERVIDORES

ESPERA_AVISO_SEGUNDOS = 2


class SysmoteApp(App):
    TITLE = "Sysmote"

    def __init__(self, connection: sqlite3.Connection | None = None, servidores=None) -> None:
        super().__init__()
        self._cierra_su_conexion = connection is None
        self.connection = connection or database.connect()
        # Servidores del agente (sysmote.server.Servidores) que viven mientras la TUI está abierta.
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
        if self.registro_abierto and self.registro_abierto[1] > datetime.now(UTC).isoformat():
            return self.registro_abierto
        return None

    def _avisar_errores(self) -> None:
        for nombre, estado in self.servidores.estado().items():
            if estado.startswith("error"):
                self.notify(f"{ETIQUETAS_SERVIDORES[nombre]}: {estado}", severity="error", timeout=20)


def main() -> None:
    from sysmote.server import Servidores

    SysmoteApp(servidores=Servidores()).run()


if __name__ == "__main__":
    main()
