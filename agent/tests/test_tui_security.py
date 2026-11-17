"""Subpestañas Seguridad y Dispositivo de la TUI con una base de datos real en memoria."""

import sqlite3
from pathlib import Path

import pytest
from textual.widgets import Button, Input, Static

from sysmote.services import auth_service, tls_service
from sysmote.tui.app import SysmoteApp
from sysmote.tui.widgets import pairing_section

SIZE = (120, 40)
SCHEMA = (Path(__file__).resolve().parent.parent / "schema.sql").read_text()


@pytest.fixture(autouse=True)
def sondeo_rapido(monkeypatch):
    monkeypatch.setattr(pairing_section, "POLL_SEGUNDOS", 0.05)


@pytest.fixture
def connection():
    connection = sqlite3.connect(":memory:")
    connection.execute("PRAGMA foreign_keys = ON")
    connection.executescript(SCHEMA)
    yield connection
    connection.close()


def _crear_cuenta(connection) -> str:
    codigo, _ = auth_service.abrir_registro(connection)
    return auth_service.registrar(connection, codigo, "alex", "Clave1", "Pixel 8")["token"]


def _texto(app, selector: str) -> str:
    return app.screen.query_one(selector, Static).content


async def _abrir_pestana(pilot, pestana: str) -> None:
    await pilot.click("#btn-pairing")
    await pilot.pause()
    await pilot.click(f"#{pestana}")
    await pilot.pause()


async def test_sin_cuenta_solo_esta_activa_la_configuracion_inicial(connection):
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-security")

        assert app.screen.query_one("#initial-setup", Button).disabled is False
        for boton in ("change-password", "close-sessions", "reset-attempts"):
            assert app.screen.query_one(f"#{boton}", Button).disabled is True


async def test_configuracion_inicial_genera_certificado_y_abre_el_registro(connection):
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-security")
        assert not tls_service.certificado_existe()

        await pilot.click("#initial-setup")
        await pilot.pause()

        info = _texto(app, "#security-info")
        assert tls_service.certificado_existe()
        assert tls_service.huella_sha256() in info
        assert f"Código de registro: {app.registro_abierto[0]}" in info
        assert auth_service.estado(connection)["registro_abierto"] is True


async def test_dispositivo_muestra_el_qr_con_el_codigo_y_el_mismo_texto_debajo(connection):
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-device")
        assert "Configuración inicial" in _texto(app, "#qr")
        assert _texto(app, "#uri") == ""

        await pilot.click("#tab-security")
        await pilot.pause()
        await pilot.click("#initial-setup")
        await pilot.pause()
        await pilot.click("#tab-device")
        await pilot.pause()

        uri = _texto(app, "#uri")
        assert uri.startswith("sysmote://emparejar?v=1&dir=")
        assert f"huella={tls_service.huella_sha256()}" in uri
        assert f"codigo={app.registro_abierto[0]}" in uri
        assert set(_texto(app, "#qr")) <= set("█▀▄ \n")


async def test_con_cuenta_el_qr_es_el_de_volver_a_emparejar_sin_codigo(connection):
    tls_service.asegurar_certificado()
    _crear_cuenta(connection)
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-device")

        uri = _texto(app, "#uri")
        assert uri.startswith("sysmote://emparejar?v=1&dir=")
        assert "codigo" not in uri


async def test_dispositivo_muestra_la_sesion_activa_y_desemparejar_la_cierra(connection):
    token = _crear_cuenta(connection)
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-device")
        info = _texto(app, "#device-info")
        assert "Dispositivo: Pixel 8" in info
        assert "Última conexión:" in info
        assert app.screen.query_one("#unpair", Button).disabled is False

        await pilot.click("#unpair")
        await pilot.pause()

        assert _texto(app, "#device-info") == "Sin dispositivo emparejado."
        assert app.screen.query_one("#unpair", Button).disabled is True
        with pytest.raises(auth_service.AuthError) as error:
            auth_service.autenticar(connection, token)
        assert error.value.codigo == "desemparejado"


async def test_dispositivo_se_actualiza_solo_cuando_la_app_hace_login(connection):
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-device")
        assert _texto(app, "#device-info") == "Sin dispositivo emparejado."

        _crear_cuenta(connection)
        await pilot.pause(0.3)

        assert "Dispositivo: Pixel 8" in _texto(app, "#device-info")


async def test_con_cuenta_se_activan_los_botones_y_se_desactiva_la_configuracion_inicial(connection):
    _crear_cuenta(connection)
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-security")

        assert app.screen.query_one("#initial-setup", Button).disabled is True
        for boton in ("change-password", "close-sessions", "reset-attempts"):
            assert app.screen.query_one(f"#{boton}", Button).disabled is False


async def test_cerrar_todas_las_sesiones(connection):
    token = _crear_cuenta(connection)
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-security")
        await pilot.click("#close-sessions")
        await pilot.pause()

        assert _texto(app, "#security-status") == "Todas las sesiones cerradas."
        with pytest.raises(auth_service.AuthError):
            auth_service.autenticar(connection, token)


async def test_reiniciar_intentos_levanta_el_bloqueo(connection):
    _crear_cuenta(connection)
    for _ in range(5):
        with pytest.raises(auth_service.AuthError):
            auth_service.login(connection, "alex", "mala", "Tablet")
    with pytest.raises(auth_service.AuthError) as bloqueado:
        auth_service.login(connection, "alex", "Clave1", "Tablet")
    assert bloqueado.value.codigo == "demasiados_intentos"

    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-security")
        await pilot.click("#reset-attempts")
        await pilot.pause()

    assert auth_service.login(connection, "alex", "Clave1", "Tablet")["estado"] == "pendiente"


async def test_cambiar_contrasena_con_contrasena_debil_muestra_los_motivos(connection):
    _crear_cuenta(connection)
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-security")
        await pilot.click("#change-password")
        await pilot.pause()

        app.screen.query_one("#new-password", Input).value = "abc"
        app.screen.query_one("#confirm-password", Input).value = "abc"
        await pilot.click("#confirm")
        await pilot.pause()

        error = _texto(app, "#dialog-error")
        assert "al menos 5 caracteres" in error
        assert "un número" in error
        assert "una mayúscula" in error


async def test_cambiar_contrasena_con_confirmacion_distinta(connection):
    _crear_cuenta(connection)
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-security")
        await pilot.click("#change-password")
        await pilot.pause()

        app.screen.query_one("#new-password", Input).value = "Nueva123"
        app.screen.query_one("#confirm-password", Input).value = "Otra123"
        await pilot.click("#confirm")
        await pilot.pause()

        assert _texto(app, "#dialog-error") == "Las contraseñas no coinciden"


async def test_cambiar_contrasena_correctamente_cierra_las_sesiones(connection):
    token = _crear_cuenta(connection)
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-security")
        await pilot.click("#change-password")
        await pilot.pause()

        app.screen.query_one("#new-password", Input).value = "Nueva123"
        app.screen.query_one("#confirm-password", Input).value = "Nueva123"
        await pilot.click("#confirm")
        await pilot.pause()

        assert _texto(app, "#security-status") == "Contraseña cambiada y sesiones cerradas."
    with pytest.raises(auth_service.AuthError):
        auth_service.autenticar(connection, token)
    assert auth_service.login(connection, "alex", "Nueva123", "Tablet")["usuario"] == "alex"


async def test_cancelar_el_cambio_de_contrasena_no_cambia_nada(connection):
    token = _crear_cuenta(connection)
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-security")
        await pilot.click("#change-password")
        await pilot.pause()
        await pilot.click("#cancel")
        await pilot.pause()

        assert _texto(app, "#security-status") == ""
    assert auth_service.autenticar(connection, token).dispositivo == "Pixel 8"


async def _con_solicitud_pendiente(connection) -> tuple[str, str]:
    token = _crear_cuenta(connection)
    solicitud = auth_service.login(connection, "alex", "Clave1", "Tablet")["solicitud"]
    return token, solicitud


async def test_la_solicitud_de_login_abre_un_dialogo_con_los_dos_dispositivos(connection):
    await _con_solicitud_pendiente(connection)
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-security")
        await pilot.pause(0.3)

        assert type(app.screen).__name__ == "LoginRequestScreen"
        texto = " ".join(str(s.content) for s in app.screen.query(Static))
        assert "Hay una sesión activa en Pixel 8." in texto
        assert "Dispositivo que lo solicita: Tablet" in texto


async def test_aprobar_la_solicitud_cierra_la_sesion_anterior(connection):
    token, solicitud = await _con_solicitud_pendiente(connection)
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-security")
        await pilot.pause(0.3)
        await pilot.click("#yes")
        await pilot.pause(0.2)

        assert type(app.screen).__name__ == "MainScreen"
    with pytest.raises(auth_service.AuthError):
        auth_service.autenticar(connection, token)
    assert auth_service.consultar_solicitud(connection, solicitud)["estado"] == "aprobada"


async def test_rechazar_la_solicitud_mantiene_la_sesion_anterior(connection):
    token, solicitud = await _con_solicitud_pendiente(connection)
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-security")
        await pilot.pause(0.3)
        await pilot.click("#no")
        await pilot.pause(0.2)

        assert type(app.screen).__name__ == "MainScreen"
    assert auth_service.autenticar(connection, token).dispositivo == "Pixel 8"
    assert auth_service.consultar_solicitud(connection, solicitud) == {"estado": "rechazada"}


async def test_la_solicitud_no_abre_dialogo_si_la_pestana_seguridad_esta_cerrada(connection):
    await _con_solicitud_pendiente(connection)
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-device")
        await pilot.pause(0.3)

        assert type(app.screen).__name__ == "MainScreen"


async def test_el_dialogo_no_se_repite_mientras_esta_abierto(connection):
    await _con_solicitud_pendiente(connection)
    app = SysmoteApp(connection=connection)
    async with app.run_test(size=SIZE) as pilot:
        await _abrir_pestana(pilot, "tab-security")
        await pilot.pause(0.5)

        assert [type(s).__name__ for s in app.screen_stack].count("LoginRequestScreen") == 1
