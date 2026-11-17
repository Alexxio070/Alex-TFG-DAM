"""Sysmote: interfaz de terminal (TUI) con Textual."""

import sqlite3

from textual.app import App

from sysmote import database
from sysmote.tui.screens.main_screen import MainScreen


class SysmoteApp(App):
    TITLE = "Sysmote"

    def __init__(self, connection: sqlite3.Connection | None = None) -> None:
        super().__init__()
        self._cierra_su_conexion = connection is None
        self.connection = connection or database.connect()
        # (código, caduca_en) del último código de registro generado; solo vive en memoria.
        self.registro_abierto: tuple[str, str] | None = None

    def on_mount(self) -> None:
        self.push_screen(MainScreen())

    def on_unmount(self) -> None:
        if self._cierra_su_conexion:
            self.connection.close()


def main() -> None:
    SysmoteApp().run()


if __name__ == "__main__":
    main()
