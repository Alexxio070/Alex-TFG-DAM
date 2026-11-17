import hashlib
import sqlite3
from datetime import UTC, datetime, timedelta
from pathlib import Path

import pytest

from sysmote.repositories import codigo_registro_repository, sesion_repository, solicitud_login_repository, usuario_repository
from sysmote.services import auth_service, limite_service, password_service
from sysmote.services.auth_service import AuthError

SCHEMA = (Path(__file__).resolve().parent.parent / "schema.sql").read_text()
CODIGO = "K7QX-M2PD-9WTR-4HNB"


@pytest.fixture
def connection():
    connection = sqlite3.connect(":memory:")
    connection.execute("PRAGMA foreign_keys = ON")
    connection.executescript(SCHEMA)
    yield connection
    connection.close()


def _en(delta: timedelta) -> str:
    return (datetime.now(UTC) + delta).isoformat()


def _abrir_registro(connection, caduca_en=None):
    codigo_registro_repository.crear(
        connection, hashlib.sha256(CODIGO.encode()).hexdigest(), caduca_en or _en(timedelta(minutes=10))
    )


def _cuenta(connection, contrasena="Clave1"):
    _abrir_registro(connection)
    return auth_service.registrar(connection, CODIGO, "alex", contrasena, "Pixel 8")


def _codigo_de_error(llamada) -> str:
    with pytest.raises(AuthError) as error:
        llamada()
    return error.value.codigo


def test_estado_sin_cuenta_ni_registro(connection):
    assert auth_service.estado(connection) == {
        "api": 1,
        "configurado": False,
        "registro_abierto": False,
        "sesion_activa": False,
    }


def test_estado_con_registro_abierto(connection):
    _abrir_registro(connection)
    assert auth_service.estado(connection)["registro_abierto"] is True


def test_estado_tras_registrar_esta_configurado_con_sesion_y_registro_cerrado(connection):
    _cuenta(connection)
    estado = auth_service.estado(connection)
    assert estado["configurado"] is True
    assert estado["registro_abierto"] is False
    assert estado["sesion_activa"] is True


@pytest.mark.parametrize(
    "contrasena, motivos",
    [("Ab1", 1), ("abcdef", 2), ("abcdef1", 1), ("ABCDEF", 1), ("Clave1", 0)],
)
def test_motivos_de_contrasena_debil(contrasena, motivos):
    assert len(auth_service.motivos_contrasena_debil(contrasena)) == motivos


def test_registrar_crea_usuario_con_argon2_y_devuelve_sesion(connection):
    resultado = _cuenta(connection)

    assert resultado["usuario"] == "alex"
    cuenta = usuario_repository.obtener_por_nombre(connection, "alex")
    assert password_service.verificar(cuenta.hash_contrasena, "Clave1")
    assert auth_service.autenticar(connection, resultado["token"]).usuario_id == cuenta.id


def test_registrar_sin_registro_abierto_da_registro_cerrado(connection):
    assert _codigo_de_error(lambda: auth_service.registrar(connection, CODIGO, "alex", "Clave1", None)) == "registro_cerrado"


def test_registrar_con_codigo_equivocado_da_codigo_invalido(connection):
    _abrir_registro(connection)
    assert _codigo_de_error(lambda: auth_service.registrar(connection, "OTRO", "alex", "Clave1", None)) == "codigo_invalido"


def test_registrar_con_codigo_caducado_da_codigo_invalido(connection):
    _abrir_registro(connection, caduca_en=_en(timedelta(minutes=-1)))
    assert _codigo_de_error(lambda: auth_service.registrar(connection, CODIGO, "alex", "Clave1", None)) == "codigo_invalido"


def test_registrar_con_contrasena_debil_no_consume_el_codigo(connection):
    _abrir_registro(connection)
    with pytest.raises(AuthError) as error:
        auth_service.registrar(connection, CODIGO, "alex", "abc", None)
    assert error.value.codigo == "contrasena_debil"
    assert len(error.value.extra["motivos"]) == 3

    assert auth_service.registrar(connection, CODIGO, "alex", "Clave1", None)["usuario"] == "alex"


def test_registrar_dos_veces_da_registro_cerrado(connection):
    _cuenta(connection)
    codigo_registro_repository.crear(connection, hashlib.sha256(b"NUEVO").hexdigest(), _en(timedelta(minutes=10)))
    assert _codigo_de_error(lambda: auth_service.registrar(connection, "NUEVO", "otro", "Clave1", None)) == "registro_cerrado"


def test_login_correcto_sin_sesion_activa_abre_sesion(connection):
    _cuenta(connection)
    sesion_repository.revocar_todas_de_usuario(connection, 1, "cerrar_todas")

    resultado = auth_service.login(connection, "alex", "Clave1", "Tablet")

    assert resultado["usuario"] == "alex"
    assert auth_service.autenticar(connection, resultado["token"]).dispositivo == "Tablet"


def test_login_con_contrasena_incorrecta(connection):
    _cuenta(connection)
    assert _codigo_de_error(lambda: auth_service.login(connection, "alex", "mala", "Tablet")) == "credenciales_invalidas"


def test_login_con_usuario_inexistente(connection):
    assert _codigo_de_error(lambda: auth_service.login(connection, "nadie", "Clave1", "Tablet")) == "credenciales_invalidas"


def test_login_con_sesion_activa_crea_solicitud_pendiente_y_no_sesion(connection):
    primera = _cuenta(connection)

    resultado = auth_service.login(connection, "alex", "Clave1", "Tablet")

    assert resultado["estado"] == "pendiente"
    assert resultado["sesion_activa_en"] == "Pixel 8"
    assert resultado["caduca_en_s"] == 300
    assert "token" not in resultado
    assert auth_service.autenticar(connection, primera["token"]).dispositivo == "Pixel 8"


def test_nuevo_login_sustituye_la_solicitud_pendiente_anterior(connection):
    _cuenta(connection)
    primera = auth_service.login(connection, "alex", "Clave1", "Tablet")
    segunda = auth_service.login(connection, "alex", "Clave1", "Tablet")

    assert solicitud_login_repository.obtener(connection, primera["solicitud"]) is None
    assert solicitud_login_repository.obtener(connection, segunda["solicitud"]) is not None


def test_solicitud_aprobada_entrega_token_una_vez_y_revoca_la_sesion_anterior(connection):
    primera = _cuenta(connection)
    solicitud = auth_service.login(connection, "alex", "Clave1", "Tablet")["solicitud"]
    assert auth_service.consultar_solicitud(connection, solicitud) == {"estado": "pendiente"}

    auth_service.responder_solicitud(connection, solicitud, aprobar=True)
    assert _codigo_de_error(lambda: auth_service.autenticar(connection, primera["token"])) == "no_autenticado"

    resultado = auth_service.consultar_solicitud(connection, solicitud)
    assert resultado["estado"] == "aprobada"
    assert auth_service.autenticar(connection, resultado["token"]).dispositivo == "Tablet"
    assert _codigo_de_error(lambda: auth_service.consultar_solicitud(connection, solicitud)) == "solicitud_desconocida"


def test_solicitud_rechazada_mantiene_la_sesion_anterior(connection):
    primera = _cuenta(connection)
    solicitud = auth_service.login(connection, "alex", "Clave1", "Tablet")["solicitud"]

    auth_service.responder_solicitud(connection, solicitud, aprobar=False)

    assert auth_service.consultar_solicitud(connection, solicitud) == {"estado": "rechazada"}
    assert auth_service.autenticar(connection, primera["token"]).dispositivo == "Pixel 8"


def test_solicitud_sin_respuesta_caduca(connection):
    _cuenta(connection)
    solicitud = auth_service.login(connection, "alex", "Clave1", "Tablet")["solicitud"]
    connection.execute("UPDATE solicitud_login SET caduca_en = ?", (_en(timedelta(seconds=-1)),))

    assert auth_service.consultar_solicitud(connection, solicitud) == {"estado": "caducada"}


def test_solicitud_desconocida(connection):
    assert _codigo_de_error(lambda: auth_service.consultar_solicitud(connection, "no-existe")) == "solicitud_desconocida"


def test_responder_solicitud_ya_resuelta_no_hace_nada(connection):
    primera = _cuenta(connection)
    solicitud = auth_service.login(connection, "alex", "Clave1", "Tablet")["solicitud"]
    auth_service.responder_solicitud(connection, solicitud, aprobar=False)

    auth_service.responder_solicitud(connection, solicitud, aprobar=True)

    assert auth_service.autenticar(connection, primera["token"]).dispositivo == "Pixel 8"


def test_sesion_caducada_por_inactividad_no_cuenta_como_activa_y_el_login_no_pide_confirmacion(connection):
    primera = _cuenta(connection)
    connection.execute("UPDATE sesion SET ultimo_acceso = ?", (_en(timedelta(days=-31)),))

    assert auth_service.estado(connection)["sesion_activa"] is False
    assert _codigo_de_error(lambda: auth_service.autenticar(connection, primera["token"])) == "no_autenticado"
    assert "token" in auth_service.login(connection, "alex", "Clave1", "Tablet")


def test_autenticar_sin_token_o_con_token_desconocido(connection):
    assert _codigo_de_error(lambda: auth_service.autenticar(connection, None)) == "no_autenticado"
    assert _codigo_de_error(lambda: auth_service.autenticar(connection, "inventado")) == "no_autenticado"


def test_autenticar_renueva_el_ultimo_acceso(connection):
    resultado = _cuenta(connection)
    connection.execute("UPDATE sesion SET ultimo_acceso = ?", (_en(timedelta(days=-10)),))

    sesion = auth_service.autenticar(connection, resultado["token"])

    assert sesion_repository.obtener_por_hash_token(connection, sesion.hash_token).ultimo_acceso > _en(timedelta(days=-1))


def test_logout_revoca_la_sesion(connection):
    resultado = _cuenta(connection)
    sesion = auth_service.autenticar(connection, resultado["token"])

    auth_service.cerrar_sesion(connection, sesion)

    assert _codigo_de_error(lambda: auth_service.autenticar(connection, resultado["token"])) == "no_autenticado"


def test_desemparejar_hace_que_la_siguiente_peticion_reciba_desemparejado(connection):
    resultado = _cuenta(connection)
    sesion = auth_service.autenticar(connection, resultado["token"])

    auth_service.desemparejar(connection, sesion)

    assert _codigo_de_error(lambda: auth_service.autenticar(connection, resultado["token"])) == "desemparejado"


def _fallar(connection, veces, usuario="alex"):
    for _ in range(veces):
        _codigo_de_error(lambda: auth_service.login(connection, usuario, "mala", "Tablet"))


def test_cinco_fallos_bloquean_el_login_incluso_con_la_contrasena_correcta(connection):
    _cuenta(connection)
    _fallar(connection, 5)

    with pytest.raises(AuthError) as error:
        auth_service.login(connection, "alex", "Clave1", "Tablet")

    assert error.value.codigo == "demasiados_intentos"
    assert 0 < error.value.extra["espera_s"] <= 600


def test_el_quinto_fallo_aun_da_credenciales_invalidas(connection):
    _cuenta(connection)
    _fallar(connection, 4)
    assert _codigo_de_error(lambda: auth_service.login(connection, "alex", "mala", "Tablet")) == "credenciales_invalidas"


def test_un_login_correcto_pone_el_contador_a_cero(connection):
    _cuenta(connection)
    _fallar(connection, 4)
    auth_service.login(connection, "alex", "Clave1", "Tablet")
    _fallar(connection, 4)

    assert auth_service.login(connection, "alex", "Clave1", "Tablet")["estado"] == "pendiente"


def test_el_login_con_solicitud_pendiente_no_cuenta_como_fallo(connection):
    _cuenta(connection)
    for _ in range(6):
        assert auth_service.login(connection, "alex", "Clave1", "Tablet")["estado"] == "pendiente"


def test_un_usuario_inexistente_tambien_se_bloquea(connection):
    _fallar(connection, 5, usuario="nadie")
    assert _codigo_de_error(lambda: auth_service.login(connection, "nadie", "x", "Tablet")) == "demasiados_intentos"


def test_cada_intento_queda_registrado_con_su_origen(connection):
    _cuenta(connection)
    _codigo_de_error(lambda: auth_service.login(connection, "alex", "mala", "Tablet", origen="127.0.0.1"))
    auth_service.login(connection, "alex", "Clave1", "Tablet", origen="127.0.0.1")

    filas = connection.execute("SELECT origen, exito FROM intento_login ORDER BY id").fetchall()
    assert filas == [("127.0.0.1", 0), ("127.0.0.1", 1)]


def test_reiniciar_intentos_permite_volver_a_entrar(connection):
    _cuenta(connection)
    _fallar(connection, 5)
    limite_service.reiniciar(connection, "alex")
    assert auth_service.login(connection, "alex", "Clave1", "Tablet")["estado"] == "pendiente"
