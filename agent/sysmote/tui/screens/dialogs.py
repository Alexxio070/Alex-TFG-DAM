"""Diálogos modales de la subpestaña Seguridad."""

from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.screen import ModalScreen
from textual.widgets import Button, Input, Static

from sysmote.services import auth_service
from sysmote.services.auth_error import AuthError

DIALOG_CSS = """
ModalScreen {
    align: center middle;
}

#dialog {
    width: 64;
    height: auto;
    border: round $primary;
    background: $surface;
    padding: 1 2;
}

#dialog-buttons {
    height: auto;
    margin-top: 1;
}

#dialog-buttons Button {
    margin-right: 1;
}
"""


class ChangePasswordScreen(ModalScreen[bool]):
    DEFAULT_CSS = DIALOG_CSS

    def compose(self) -> ComposeResult:
        with Vertical(id="dialog"):
            yield Static("Cambiar contraseña")
            yield Input(placeholder="Contraseña nueva", password=True, id="new-password")
            yield Input(placeholder="Repite la contraseña", password=True, id="confirm-password")
            yield Static("", id="dialog-error", markup=False)
            with Horizontal(id="dialog-buttons"):
                yield Button("Cambiar", id="confirm", variant="primary")
                yield Button("Cancelar", id="cancel")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "cancel":
            self.dismiss(False)
            return
        nueva = self.query_one("#new-password", Input).value
        if nueva != self.query_one("#confirm-password", Input).value:
            self._mostrar_error("Las contraseñas no coinciden")
            return
        try:
            auth_service.cambiar_contrasena(self.app.connection, nueva)
        except AuthError as error:
            self._mostrar_error("\n".join(error.extra["motivos"]))
            return
        self.dismiss(True)

    def _mostrar_error(self, texto: str) -> None:
        self.query_one("#dialog-error", Static).update(texto)


class LoginRequestScreen(ModalScreen[bool]):
    DEFAULT_CSS = DIALOG_CSS

    def __init__(self, sesion_activa_en: str, solicitante: str) -> None:
        super().__init__()
        self._sesion_activa_en = sesion_activa_en
        self._solicitante = solicitante

    def compose(self) -> ComposeResult:
        with Vertical(id="dialog"):
            yield Static(
                f"Hay una sesión activa en {self._sesion_activa_en}.\n"
                "¿Quieres cerrarla e iniciar una nueva?\n\n"
                f"Dispositivo que lo solicita: {self._solicitante}",
                markup=False,
            )
            with Horizontal(id="dialog-buttons"):
                yield Button("Sí, sobrescribir la sesión", id="yes", variant="primary")
                yield Button("No, mantener la sesión anterior", id="no")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        self.dismiss(event.button.id == "yes")
