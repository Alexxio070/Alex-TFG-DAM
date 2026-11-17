"""Sección «Emparejamiento»: subpestañas Dispositivo, Seguridad y Servicio."""

from textual.app import ComposeResult
from textual.containers import Container, Horizontal, Vertical
from textual.widgets import Button, ContentSwitcher

from sysmote.tui.sections import select_section
from sysmote.tui.widgets.device_tab import DeviceTab
from sysmote.tui.widgets.security_tab import SecurityTab

POLL_SEGUNDOS = 1

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
        min-width: 8;
        margin-right: 1;
    }
    """

    def compose(self) -> ComposeResult:
        with Horizontal(id="tabs"):
            yield Button("Dispositivo", id="tab-device", variant="primary")
            yield Button("Seguridad", id="tab-security")
            yield Button("Servicio", id="tab-service")

        with ContentSwitcher(id="pairing-tabs", initial="device"):
            yield DeviceTab(id="device")
            yield SecurityTab(id="security")
            yield ServiceTab(id="service")

    def on_mount(self) -> None:
        self.set_interval(POLL_SEGUNDOS, self._sondear)

    def _sondear(self) -> None:
        if not self.display:
            return
        dispositivo = self.query_one(DeviceTab)
        seguridad = self.query_one(SecurityTab)
        if dispositivo.display:
            dispositivo.refrescar()
        if seguridad.display:
            seguridad.refrescar()
            seguridad.comprobar_solicitud()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        select_section(self, TAB_IDS, "#pairing-tabs", "#tabs Button", event.button)
        if event.button.id in TAB_IDS:
            self._sondear()


class ServiceTab(Vertical):
    """Instalar, quitar y consultar el estado del servicio systemd (fase 5)."""

    def compose(self) -> ComposeResult:
        yield Button("Instalar servicio", id="install-service", disabled=True)
        yield Button("Quitar servicio", id="remove-service", disabled=True)
        yield Button("Estado", id="service-status", disabled=True)
