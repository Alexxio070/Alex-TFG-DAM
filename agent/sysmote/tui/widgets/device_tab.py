"""Subpestaña Dispositivo: QR de emparejamiento y datos de la sesión activa."""

from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical, VerticalScroll
from textual.widgets import Button, Static

from sysmote.services import auth_service, pairing_service, tls_service
from sysmote.tui.widgets.formato import fecha_local

SIN_QR = "Pulsa «Configuración inicial» en Seguridad para generar el QR."


class DeviceTab(VerticalScroll):
    DEFAULT_CSS = """
    DeviceTab Horizontal#device-row {
        height: auto;
    }

    DeviceTab #qr-column {
        width: auto;
        height: auto;
        margin-right: 4;
    }

    DeviceTab #qr {
        width: auto;
        padding: 0 1;
    }

    DeviceTab #qr.with-qr {
        background: white;
        color: black;
    }

    DeviceTab #device-column {
        width: 1fr;
        height: auto;
    }

    DeviceTab #unpair {
        margin-top: 1;
    }
    """

    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)
        self._uri_mostrada: str | None = None

    def compose(self) -> ComposeResult:
        with Horizontal(id="device-row"):
            with Vertical(id="qr-column"):
                yield Static(SIN_QR, id="qr", markup=False)
                yield Static("", id="uri", markup=False)
            with Vertical(id="device-column"):
                yield Static("", id="device-info", markup=False)
                yield Button("Desemparejar", id="unpair", variant="error", disabled=True)

    def on_mount(self) -> None:
        self._iroh = pairing_service.identificador_iroh()
        self.refrescar()

    def refrescar(self) -> None:
        conexion = self.app.connection
        sesion = auth_service.sesion_activa(conexion)
        if sesion is None:
            texto = "Sin dispositivo emparejado."
        else:
            texto = (
                f"Dispositivo: {sesion.dispositivo}\n"
                f"Conectado desde: {fecha_local(sesion.creado_en)}\n"
                f"Última conexión: {fecha_local(sesion.ultimo_acceso)}\n"
                "Estado: sesión activa"
            )
        self.query_one("#device-info", Static).update(texto)
        self.query_one("#unpair", Button).disabled = sesion is None
        self._mostrar_qr(self._uri(auth_service.estado(conexion)["configurado"]))

    def _uri(self, configurado: bool) -> str | None:
        if not tls_service.certificado_existe():
            return None
        direccion = pairing_service.direccion_lan()
        huella = tls_service.huella_sha256()
        if configurado:
            return pairing_service.uri_emparejamiento(direccion, huella, iroh=self._iroh)
        abierto = self.app.codigo_registro_vigente()
        if abierto is None:
            return None
        return pairing_service.uri_emparejamiento(direccion, huella, codigo=abierto[0], iroh=self._iroh)

    def _mostrar_qr(self, uri: str | None) -> None:
        if uri == self._uri_mostrada:
            return
        self._uri_mostrada = uri
        qr = self.query_one("#qr", Static)
        qr.set_class(uri is not None, "with-qr")
        qr.update(pairing_service.qr_texto(uri) if uri else SIN_QR)
        self.query_one("#uri", Static).update(uri or "")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "unpair":
            auth_service.desemparejar_sesion_activa(self.app.connection)
            self.refrescar()
