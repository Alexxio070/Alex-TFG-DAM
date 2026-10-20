"""Pantalla principal: banner, área de datos y la barra de cuatro botones."""

from textual.app import ComposeResult
from textual.containers import Container, Horizontal
from textual.screen import Screen
from textual.widgets import Button, ContentSwitcher, Footer, Static

from companion.tui.widgets.database_section import DatabaseSection
from companion.tui.widgets.history_section import HistorySection
from companion.tui.widgets.notes_section import NotesSection
from companion.tui.widgets.pairing_section import PairingSection

LINUX_ART = [
    "██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗",
    "██║     ██║████╗  ██║██║   ██║╚██╗██╔╝",
    "██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝ ",
    "██║     ██║██║╚██╗██║██║   ██║ ██╔██╗ ",
    "███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗",
    "╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝",
]
SYSTEM_ART = [
    "███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗",
    "██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║",
    "███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║",
    "╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║",
    "███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║",
    "╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝",
]
_LINUX_WIDTH = max(len(line) for line in LINUX_ART)
BANNER = "\n".join(f"{left.ljust(_LINUX_WIDTH)}  {right}" for left, right in zip(LINUX_ART, SYSTEM_ART))

SECTION_IDS = {
    "btn-pairing": "pairing",
    "btn-history": "history",
    "btn-database": "database",
    "btn-notes": "notes",
}


class MainScreen(Screen):
    """Banner arriba, área de datos en el centro, barra de botones abajo."""

    BINDINGS = [("q", "quit", "Salir")]

    CSS = """
    #banner {
        width: 100%;
        height: auto;
        align-horizontal: center;
        padding: 1 0;
        border-bottom: heavy $primary;
    }

    #banner Static {
        color: $success;
        text-style: bold;
    }

    #data {
        height: 1fr;
        border: round $primary;
        border-title-align: left;
        padding: 1 2;
    }

    #sections, .section {
        height: 1fr;
    }

    #buttons {
        height: auto;
        padding: 1 1 0 1;
    }

    #buttons Button {
        width: 1fr;
        margin: 0 1;
    }

    Footer, FooterKey, .footer-key--key, .footer-key--description {
        background: transparent;
    }
    """

    def compose(self) -> ComposeResult:
        with Container(id="banner"):
            yield Static(BANNER)

        with Container(id="data"):
            with ContentSwitcher(id="sections"):
                yield PairingSection(id="pairing", classes="section")
                yield HistorySection(id="history", classes="section")
                yield DatabaseSection(id="database", classes="section")
                yield NotesSection(id="notes", classes="section")

        with Horizontal(id="buttons"):
            yield Button("Emparejamiento", id="btn-pairing")
            yield Button("Historial", id="btn-history")
            yield Button("Base de datos", id="btn-database")
            yield Button("Notas", id="btn-notes")

        yield Footer()

    def on_mount(self) -> None:
        self.query_one("#data").border_title = "Datos"

    def on_button_pressed(self, event: Button.Pressed) -> None:
        section = SECTION_IDS.get(event.button.id)
        if section is None:
            return
        self.query_one("#sections", ContentSwitcher).current = section
        for button in self.query("#buttons Button"):
            button.variant = "primary" if button is event.button else "default"
