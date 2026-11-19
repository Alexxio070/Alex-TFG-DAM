"""Lógica de autenticación: registro, login, solicitudes de login, sesiones, límite y acciones de la TUI."""

import re
from datetime import UTC, datetime, timedelta

import pytest

from sysmote.repositories import (
    codigo_registro_repository,
    sesion_repository,
    solicitud_login_repository,
    usuario_repository,
)
from sysmote.services import auth_service, limite_service, password_service, token_service
from sysmote.services.auth_service import AuthError

CODIGO = "K7QX-M2PD-9WTR-4HNB"


def _en(delta: timedelta) -> str:
    return (datetime.now(UTC) + delta).isoformat()


def _abrir_registro(connection, caduca_en=None):
    codigo_registro_repository.crear(
        connection, auth_service.hash_codigo(CODIGO), caduca_en or _en(timedelta(minutes=10))
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
    assert (
        _codigo_de_error(
            lambda: auth_service.registrar(connection, CODIGO, "alex", "Clave1", "Móvil")
        )
        == "registro_cerrado"
    )


def test_registrar_con_codigo_equivocado_da_codigo_invalido(connection):
    _abrir_registro(connection)
    assert (
        _codigo_de_error(
            lambda: auth_service.registrar(connection, "OTRO", "alex", "Clave1", "Móvil")
        )
        == "codigo_invalido"
    )


def test_registrar_con_el_codigo_caducado_da_codigo_caducado(connection):
    _abrir_registro(connection, caduca_en=_en(timedelta(minutes=-1)))
    assert (
        _codigo_de_error(
            lambda: auth_service.registrar(connection, CODIGO, "alex", "Clave1", "Móvil")
        )
        == "codigo_caducado"
    )


def test_registrar_con_otro_codigo_cuando_solo_hay_uno_caducado_da_codigo_invalido(connection):
    _abrir_registro(connection, caduca_en=_en(timedelta(minutes=-1)))
    assert (
        _codigo_de_error(
            lambda: auth_service.registrar(connection, "OTRO", "alex", "Clave1", "Móvil")
        )
        == "codigo_invalido"
    )


def test_registrar_con_un_codigo_ya_usado_da_codigo_invalido(connection):
    _abrir_registro(connection)
    codigo = codigo_registro_repository.obtener_por_hash(
        connection, auth_service.hash_codigo(CODIGO)
    )
    codigo_registro_repository.marcar_usado(connection, codigo.id)
    assert (
        _codigo_de_error(
            lambda: auth_service.registrar(connection, CODIGO, "alex", "Clave1", "Móvil")
        )
        == "codigo_invalido"
    )


def test_el_codigo_caducado_deja_de_reconocerse_al_abrir_un_registro_nuevo(connection):
    _abrir_registro(connection, caduca_en=_en(timedelta(minutes=-1)))
    auth_service.abrir_registro(connection)
    assert (
        _codigo_de_error(
            lambda: auth_service.registrar(connection, CODIGO, "alex", "Clave1", "Móvil")
        )
        == "codigo_invalido"
    )


def test_el_codigo_caducado_se_distingue_antes_que_la_contrasena_debil(connection):
    _abrir_registro(connection, caduca_en=_en(timedelta(minutes=-1)))
    assert (
        _codigo_de_error(lambda: auth_service.registrar(connection, CODIGO, "alex", "abc", "Móvil"))
        == "codigo_caducado"
    )


def test_registrar_con_contrasena_debil_no_consume_el_codigo(connection):
    _abrir_registro(connection)
    with pytest.raises(AuthError) as error:
        auth_service.registrar(connection, CODIGO, "alex", "abc", "Móvil")
    assert error.value.codigo == "contrasena_debil"
    assert len(error.value.extra["motivos"]) == 3

    assert (
        auth_service.registrar(connection, CODIGO, "alex", "Clave1", "Móvil")["usuario"] == "alex"
    )


def test_registrar_dos_veces_da_registro_cerrado(connection):
    _cuenta(connection)
    codigo_registro_repository.crear(
        connection, auth_service.hash_codigo("NUEVO"), _en(timedelta(minutes=10))
    )
    assert (
        _codigo_de_error(
            lambda: auth_service.registrar(connection, "NUEVO", "otro", "Clave1", "Móvil")
        )
        == "registro_cerrado"
    )


def test_dos_registros_simultaneos_solo_crean_una_cuenta(connection, monkeypatch):
    _cuenta(connection)
    codigo_registro_repository.crear(
        connection, auth_service.hash_codigo("NUEVO"), _en(timedelta(minutes=10))
    )
    # Simula la carrera: la comprobación de «ya hay cuenta» pasa porque el otro registro aún no había insertado.
    monkeypatch.setattr(usuario_repository, "existe_alguno", lambda _connection: False)

    assert (
        _codigo_de_error(
            lambda: auth_service.registrar(connection, "NUEVO", "otro", "Clave1", "Móvil")
        )
        == "registro_cerrado"
    )
    assert usuario_repository.obtener_por_nombre(connection, "otro") is None


def test_login_con_usuario_inexistente_tambien_ejecuta_argon2(connection, monkeypatch):
    verificadas = []
    monkeypatch.setattr(
        password_service,
        "verificar",
        lambda hash_contrasena, contrasena: verificadas.append(contrasena) or False,
    )

    assert (
        _codigo_de_error(lambda: auth_service.login(connection, "nadie", "Clave1", "Pixel 8"))
        == "credenciales_invalidas"
    )
    assert verificadas == ["Clave1"]


def test_login_correcto_sin_sesion_activa_abre_sesion(connection):
    _cuenta(connection)
    sesion_repository.revocar_todas_de_usuario(connection, 1, "cerrar_todas")

    resultado = auth_service.login(connection, "alex", "Clave1", "Tablet")

    assert resultado["usuario"] == "alex"
    assert auth_service.autenticar(connection, resultado["token"]).dispositivo == "Tablet"


def test_login_con_contrasena_incorrecta(connection):
    _cuenta(connection)
    assert (
        _codigo_de_error(lambda: auth_service.login(connection, "alex", "mala", "Tablet"))
        == "credenciales_invalidas"
    )


def test_login_con_usuario_inexistente(connection):
    assert (
        _codigo_de_error(lambda: auth_service.login(connection, "nadie", "Clave1", "Tablet"))
        == "credenciales_invalidas"
    )


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
    assert (
        _codigo_de_error(lambda: auth_service.autenticar(connection, primera["token"]))
        == "no_autenticado"
    )

    resultado = auth_service.consultar_solicitud(connection, solicitud)
    assert resultado["estado"] == "aprobada"
    assert auth_service.autenticar(connection, resultado["token"]).dispositivo == "Tablet"
    assert (
        _codigo_de_error(lambda: auth_service.consultar_solicitud(connection, solicitud))
        == "solicitud_desconocida"
    )


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
    assert (
        _codigo_de_error(lambda: auth_service.consultar_solicitud(connection, "no-existe"))
        == "solicitud_desconocida"
    )


def test_responder_solicitud_ya_resuelta_no_hace_nada(connection):
    primera = _cuenta(connection)
    solicitud = auth_service.login(connection, "alex", "Clave1", "Tablet")["solicitud"]
    auth_service.responder_solicitud(connection, solicitud, aprobar=False)

    auth_service.responder_solicitud(connection, solicitud, aprobar=True)

    assert auth_service.autenticar(connection, primera["token"]).dispositivo == "Pixel 8"


def test_sesion_caducada_por_inactividad_no_cuenta_como_activa_y_el_login_no_pide_confirmacion(
    connection,
):
    primera = _cuenta(connection)
    connection.execute("UPDATE sesion SET ultimo_acceso = ?", (_en(timedelta(days=-31)),))

    assert auth_service.estado(connection)["sesion_activa"] is False
    assert (
        _codigo_de_error(lambda: auth_service.autenticar(connection, primera["token"]))
        == "no_autenticado"
    )
    assert "token" in auth_service.login(connection, "alex", "Clave1", "Tablet")


def test_autenticar_sin_token_o_con_token_desconocido(connection):
    assert _codigo_de_error(lambda: auth_service.autenticar(connection, None)) == "no_autenticado"
    assert (
        _codigo_de_error(lambda: auth_service.autenticar(connection, "inventado"))
        == "no_autenticado"
    )


def test_autenticar_renueva_el_ultimo_acceso(connection):
    resultado = _cuenta(connection)
    connection.execute("UPDATE sesion SET ultimo_acceso = ?", (_en(timedelta(days=-10)),))

    sesion = auth_service.autenticar(connection, resultado["token"])

    assert sesion_repository.obtener_por_hash_token(
        connection, sesion.hash_token
    ).ultimo_acceso > _en(timedelta(days=-1))


def test_logout_revoca_la_sesion(connection):
    resultado = _cuenta(connection)
    sesion = auth_service.autenticar(connection, resultado["token"])

    auth_service.cerrar_sesion(connection, sesion)

    assert (
        _codigo_de_error(lambda: auth_service.autenticar(connection, resultado["token"]))
        == "no_autenticado"
    )


def test_desemparejar_hace_que_la_siguiente_peticion_reciba_desemparejado(connection):
    resultado = _cuenta(connection)
    sesion = auth_service.autenticar(connection, resultado["token"])

    auth_service.desemparejar(connection, sesion)

    assert (
        _codigo_de_error(lambda: auth_service.autenticar(connection, resultado["token"]))
        == "desemparejado"
    )


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
    assert (
        _codigo_de_error(lambda: auth_service.login(connection, "alex", "mala", "Tablet"))
        == "credenciales_invalidas"
    )


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
    assert (
        _codigo_de_error(lambda: auth_service.login(connection, "nadie", "x", "Tablet"))
        == "demasiados_intentos"
    )


def test_cada_intento_queda_registrado_con_su_origen(connection):
    _cuenta(connection)
    _codigo_de_error(
        lambda: auth_service.login(connection, "alex", "mala", "Tablet", origen="127.0.0.1")
    )
    auth_service.login(connection, "alex", "Clave1", "Tablet", origen="127.0.0.1")

    filas = connection.execute("SELECT origen, exito FROM intento_login ORDER BY id").fetchall()
    assert filas == [("127.0.0.1", 0), ("127.0.0.1", 1)]


def test_reiniciar_intentos_permite_volver_a_entrar(connection):
    _cuenta(connection)
    _fallar(connection, 5)
    limite_service.reiniciar(connection, "alex")
    assert auth_service.login(connection, "alex", "Clave1", "Tablet")["estado"] == "pendiente"


def test_abrir_registro_genera_un_codigo_de_16_caracteres_base32_con_guiones(connection):
    codigo, caduca_en = auth_service.abrir_registro(connection)

    assert re.fullmatch(r"[A-Z2-7]{4}(-[A-Z2-7]{4}){3}", codigo)
    assert 540 < (datetime.fromisoformat(caduca_en) - datetime.now(UTC)).total_seconds() <= 600
    assert auth_service.estado(connection)["registro_abierto"] is True


def test_abrir_registro_guarda_solo_el_hash(connection):
    codigo, _ = auth_service.abrir_registro(connection)
    guardado = connection.execute("SELECT hash_codigo FROM codigo_registro").fetchone()[0]
    assert codigo not in guardado
    assert guardado == auth_service.hash_codigo(codigo)


def test_abrir_registro_invalida_el_codigo_anterior(connection):
    primero, _ = auth_service.abrir_registro(connection)
    auth_service.abrir_registro(connection)
    assert (
        _codigo_de_error(
            lambda: auth_service.registrar(connection, primero, "alex", "Clave1", "Móvil")
        )
        == "codigo_invalido"
    )


def test_el_codigo_sirve_escrito_sin_guiones_y_en_minusculas(connection):
    codigo, _ = auth_service.abrir_registro(connection)
    escrito_a_mano = codigo.replace("-", "").lower()
    assert (
        auth_service.registrar(connection, escrito_a_mano, "alex", "Clave1", "Móvil")["usuario"]
        == "alex"
    )


def test_el_codigo_sirve_si_se_teclea_cero_por_o_y_uno_por_i(connection):
    assert auth_service.hash_codigo("AB0I-1OAB") == auth_service.hash_codigo("ABOI-IOAB")


def test_abrir_registro_con_cuenta_creada_falla(connection):
    _cuenta(connection)
    assert _codigo_de_error(lambda: auth_service.abrir_registro(connection)) == "ya_configurado"


def test_cambiar_contrasena_actualiza_el_hash_y_revoca_las_sesiones(connection):
    resultado = _cuenta(connection)

    auth_service.cambiar_contrasena(connection, "Nueva123")

    assert (
        _codigo_de_error(lambda: auth_service.autenticar(connection, resultado["token"]))
        == "no_autenticado"
    )
    assert auth_service.login(connection, "alex", "Nueva123", "Tablet")["usuario"] == "alex"
    assert (
        _codigo_de_error(lambda: auth_service.login(connection, "alex", "Clave1", "Tablet"))
        == "credenciales_invalidas"
    )


def test_cambiar_contrasena_levanta_el_bloqueo_por_intentos(connection):
    _cuenta(connection)
    _fallar(connection, 5)

    auth_service.cambiar_contrasena(connection, "Nueva123")

    assert auth_service.login(connection, "alex", "Nueva123", "Tablet")["usuario"] == "alex"


def test_cambiar_contrasena_debil_no_cambia_nada(connection):
    resultado = _cuenta(connection)

    with pytest.raises(AuthError) as error:
        auth_service.cambiar_contrasena(connection, "abc")

    assert error.value.codigo == "contrasena_debil"
    assert auth_service.autenticar(connection, resultado["token"]).dispositivo == "Pixel 8"


def test_cerrar_todas_las_sesiones(connection):
    resultado = _cuenta(connection)
    auth_service.cerrar_todas_las_sesiones(connection)
    assert (
        _codigo_de_error(lambda: auth_service.autenticar(connection, resultado["token"]))
        == "no_autenticado"
    )
    assert "token" in auth_service.login(connection, "alex", "Clave1", "Tablet")


def test_solicitud_pendiente_la_devuelve_y_ignora_las_caducadas(connection):
    _cuenta(connection)
    assert auth_service.solicitud_pendiente(connection) is None

    solicitud = auth_service.login(connection, "alex", "Clave1", "Tablet")["solicitud"]
    assert auth_service.solicitud_pendiente(connection).id == solicitud

    connection.execute("UPDATE solicitud_login SET caduca_en = ?", (_en(timedelta(seconds=-1)),))
    assert auth_service.solicitud_pendiente(connection) is None
    assert auth_service.consultar_solicitud(connection, solicitud) == {"estado": "caducada"}


def test_desemparejar_sin_sesion_activa_no_hace_nada(connection):
    resultado = _cuenta(connection)
    auth_service.cerrar_todas_las_sesiones(connection)

    auth_service.desemparejar_sesion_activa(connection)

    sesion = sesion_repository.obtener_por_hash_token(
        connection, token_service.hashear(resultado["token"])
    )
    assert sesion.motivo_revocacion == "cerrar_todas"


def test_desemparejar_sesion_activa_desde_la_tui(connection):
    resultado = _cuenta(connection)
    assert auth_service.sesion_activa(connection).dispositivo == "Pixel 8"

    auth_service.desemparejar_sesion_activa(connection)

    assert auth_service.sesion_activa(connection) is None
    assert (
        _codigo_de_error(lambda: auth_service.autenticar(connection, resultado["token"]))
        == "desemparejado"
    )
