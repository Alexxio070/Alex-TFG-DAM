"""Sección «Emparejamiento»: subpestañas Dispositivo, Seguridad y Servicio."""

from textual.app import ComposeResult
from textual.containers import Container, Horizontal, Vertical
from textual.widgets import Button, ContentSwitcher, Static

TAB_IDS = {
    "tab-device": "device",
    "tab-security": "security",
    "tab-service": "service",
}


class PairingSection(Container):
    """Contenedor con la barra de subpestañas y su propio ContentSwitcher."""

    DEFAULT_CSS = """
    PairingSection Horizontal#tabs {
        height: auto;
        margin-bottom: 1;
    }

    PairingSection Horizontal#tabs Button {
        width: auto;
        min-width: 14;
        margin-right: 1;
    }

    PairingSection Button.-selected {
        background: ansi_blue;
        border: round ansi_cyan;
        color: ansi_bright_white;
    }
    """

    def compose(self) -> ComposeResult:
        with Horizontal(id="tabs"):
            yield Button("Dispositivo", id="tab-device")
            yield Button("Seguridad", id="tab-security")
            yield Button("Servicio", id="tab-service")

        with ContentSwitcher(id="pairing-tabs", initial="device"):
            yield DeviceTab(id="device")
            yield SecurityTab(id="security")
            yield ServiceTab(id="service")

    def on_mount(self) -> None:
        self.query_one("#tab-device", Button).set_class(True, "-selected")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        tab = TAB_IDS.get(event.button.id)
        if tab is None:
            return
        self.query_one("#pairing-tabs", ContentSwitcher).current = tab
        for button in self.query("#tabs Button"):
            button.set_class(button is event.button, "-selected")


class DeviceTab(Vertical):
    """QR de emparejamiento y datos del dispositivo conectado."""

    def compose(self) -> ComposeResult:
        # TODO: código QR real con `qrcode` y datos de `sesion` (fase 9).
        yield Static("Sin dispositivo emparejado.")
        yield Button("Desemparejar", id="unpair", variant="error", disabled=True)


class SecurityTab(Vertical):
    """Configuración inicial, cambiar contraseña, cerrar sesiones (fase 3)."""

    def compose(self) -> ComposeResult:
        # TODO: dirección, huella TLS e identificador iroh reales.
        yield Static("Dirección: —\nHuella del certificado: —\nIdentificador iroh: —")
        yield Button("Configuración inicial", id="initial-setup", disabled=True)
        yield Button("Cambiar contraseña", id="change-password", disabled=True)
        yield Button("Cerrar todas las sesiones", id="close-sessions", disabled=True)


class ServiceTab(Vertical):
    """Instalar, quitar y consultar el estado del servicio systemd (fase 5)."""

    def compose(self) -> ComposeResult:
        yield Button("Instalar servicio", id="install-service", disabled=True)
        yield Button("Quitar servicio", id="remove-service", disabled=True)
        yield Button("Estado", id="service-status", disabled=True)
