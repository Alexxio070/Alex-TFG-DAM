"""Sección «Notas»: CRUD de notas del espacio compartido (fase 9)."""

from textual.app import ComposeResult
from textual.containers import Vertical
from textual.widgets import Button, DataTable


class NotesSection(Vertical):
    """Tabla fecha/origen/contenido, vacía hasta que exista el CRUD de notas."""

    def compose(self) -> ComposeResult:
        yield DataTable(id="notes-table", zebra_stripes=True, cursor_type="row")
        yield Button("+ Añadir nota", id="add-note", disabled=True)

    def on_mount(self) -> None:
        table = self.query_one("#notes-table", DataTable)
        table.add_columns("Fecha", "Origen", "Contenido")
        # TODO: CRUD real sobre la tabla `nota` (fase 9).
