"""Sección «Base de datos»: navegador en vivo de las tablas de schema.sql."""

from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical, VerticalScroll
from textual.widgets import Button, Static


class DatabaseSection(Vertical):
    """Lista de tablas con scroll, y los botones de exportación debajo."""

    def compose(self) -> ComposeResult:
        with VerticalScroll(id="db-scroll"):
            # TODO: una tabla por cada tabla de schema.sql (nombre, columnas,
            # filas), separadas por un divisor, leídas con sqlite_master y
            # PRAGMA table_info. La base de datos ya existe; falta la vista.
            yield Static("Sin tablas todavía.")

        with Horizontal(id="export-buttons"):
            yield Button("Exportar datos", id="export-data", disabled=True)
            yield Button("Exportar estructura", id="export-schema", disabled=True)
