"""Subpestaña Seguridad: configuración inicial, contraseña, sesiones y solicitudes de login."""

from textual.app import ComposeResult
from textual.containers import Vertical
from textual.widgets import Button, Static

from sysmote.models.auth import SolicitudLogin
from sysmote.services import auth_service, pairing_service, tls_service
from sysmote.tui.screens.dialogs import ChangePasswordScreen, LoginRequestScreen
from sysmote.tui.widgets.formato import ETIQUETAS_SERVIDORES, hora_local


class SecurityTab(Vertical):
    """Datos de conexión del agente y botones de seguridad; abre el diálogo de las solicitudes de login."""

    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)
        self._dialogo_abierto = False

    def compose(self) -> ComposeResult:
        yield Static("", id="security-info", markup=False)
        yield Button("Configuración inicial", id="initial-setup")
        yield Button("Cambiar contraseña", id="change-password")
        yield Button("Cerrar todas las sesiones", id="close-sessions")
        yield Button("Reiniciar intentos", id="reset-attempts")
        yield Static("", id="security-status", markup=False)

    def on_mount(self) -> None:
        self._iroh = pairing_service.identificador_iroh()
        self.refrescar()

    def refrescar(self) -> None:
        """Actualiza los datos mostrados y qué botones se pueden pulsar según haya cuenta o no."""
        huella = tls_service.huella_sha256() if tls_service.certificado_existe() else "—"
        lineas = [
            f"Dirección: {pairing_service.direccion_lan()}",
            f"Huella del certificado: {huella}",
            f"Identificador iroh: {self._iroh}",
        ]
        if self.app.servidores is not None:
            for nombre, estado in self.app.servidores.estado().items():
                lineas.append(f"{ETIQUETAS_SERVIDORES[nombre]}: {estado}")
        abierto = self.app.codigo_registro_vigente()
        if abierto:
            lineas.append(
                f"Código de registro: {abierto[0]} (caduca a las {hora_local(abierto[1])})"
            )
        self.query_one("#security-info", Static).update("\n".join(lineas))

        configurado = auth_service.estado(self.app.connection)["configurado"]
        self.query_one("#initial-setup", Button).disabled = configurado
        for boton in ("#change-password", "#close-sessions", "#reset-attempts"):
            self.query_one(boton, Button).disabled = not configurado

    def comprobar_solicitud(self) -> None:
        """Si la app ha pedido un login con otra sesión activa, pregunta al usuario qué hacer.

        `PairingSection` lo llama cada segundo mientras esta pestaña está visible.
        """
        if self._dialogo_abierto:
            return
        solicitud = auth_service.solicitud_pendiente(self.app.connection)
        if solicitud is None:
            return
        activa = auth_service.sesion_activa(self.app.connection)
        self._dialogo_abierto = True
        self.app.push_screen(
            LoginRequestScreen(
                activa.dispositivo if activa else "otro dispositivo", solicitud.dispositivo
            ),
            lambda aprobar: self._responder(solicitud, bool(aprobar)),
        )

    def _responder(self, solicitud: SolicitudLogin, aprobar: bool) -> None:
        auth_service.responder_solicitud(self.app.connection, solicitud.id, aprobar)
        self._dialogo_abierto = False
        self._estado(
            "Sesión anterior cerrada, la app ya puede entrar."
            if aprobar
            else "Sesión anterior mantenida."
        )

    def _estado(self, texto: str) -> None:
        self.query_one("#security-status", Static).update(texto)

    def on_button_pressed(self, event: Button.Pressed) -> None:
        conexion = self.app.connection
        match event.button.id:
            case "initial-setup":
                tls_service.asegurar_certificado()
                self.app.registro_abierto = auth_service.abrir_registro(conexion)
                self._estado(
                    "Registro abierto durante 10 minutos. El QR está en la pestaña Dispositivo."
                )
            case "change-password":
                self.app.push_screen(
                    ChangePasswordScreen(),
                    lambda cambiada: (
                        self._estado("Contraseña cambiada y sesiones cerradas.")
                        if cambiada
                        else None
                    ),
                )
            case "close-sessions":
                auth_service.cerrar_todas_las_sesiones(conexion)
                self._estado("Todas las sesiones cerradas.")
            case "reset-attempts":
                auth_service.reiniciar_intentos(conexion)
                self._estado("Intentos de login reiniciados.")
            case _:
                return
        self.refrescar()
