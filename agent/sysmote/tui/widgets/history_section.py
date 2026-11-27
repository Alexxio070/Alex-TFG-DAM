"""Sección «Historial»: acciones rápidas (MACRO) y comandos de terminal."""

from textual.app import ComposeResult
from textual.containers import Container
from textual.widgets import DataTable


class HistorySection(Container):
    """Tabla fecha/hora, origen y comando, vacía hasta que haya datos reales."""

    def compose(self) -> ComposeResult:
        yield DataTable(id="history-table", zebra_stripes=True, cursor_type="row")

    def on_mount(self) -> None:
        table = self.query_one("#history-table", DataTable)
        table.add_columns("Fecha y hora", "Origen", "Comando")
        # TODO: combinar `ejecucion` (MACRO, fase 5) con el log de comandos de
        # terminal (TERMINAL, fase 5) solo al mostrarlos, ordenado por fecha.
