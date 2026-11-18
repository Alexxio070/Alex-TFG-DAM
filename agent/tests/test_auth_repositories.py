import sqlite3
from pathlib import Path

import pytest

from sysmote.repositories import (
    intento_login_repository,
    sesion_repository,
    solicitud_login_repository,
    usuario_repository,
)

SCHEMA = (Path(__file__).resolve().parent.parent / "schema.sql").read_text()


@pytest.fixture
def connection():
    connection = sqlite3.connect(":memory:")
    connection.execute("PRAGMA foreign_keys = ON")
    connection.executescript(SCHEMA)
    yield connection
    connection.close()


def test_crear_y_obtener_usuario_por_nombre(connection):
    usuario_repository.crear(connection, "alex", "hash-falso")
    usuario = usuario_repository.obtener_por_nombre(connection, "alex")
    assert usuario.nombre_usuario == "alex"
    assert usuario.hash_contrasena == "hash-falso"


def test_obtener_por_nombre_inexistente_devuelve_none(connection):
    assert usuario_repository.obtener_por_nombre(connection, "nadie") is None


def test_existe_alguno(connection):
    assert usuario_repository.existe_alguno(connection) is False
    usuario_repository.crear(connection, "alex", "hash-falso")
    assert usuario_repository.existe_alguno(connection) is True


def test_actualizar_contrasena(connection):
    usuario = usuario_repository.crear(connection, "alex", "hash-viejo")
    usuario_repository.actualizar_contrasena(connection, usuario.id, "hash-nuevo")
    assert usuario_repository.obtener_por_nombre(connection, "alex").hash_contrasena == "hash-nuevo"


def test_sesion_se_crea_activa_y_se_encuentra_por_token(connection):
    usuario = usuario_repository.crear(connection, "alex", "hash-falso")
    sesion = sesion_repository.crear(connection, usuario.id, "hash-token", "Pixel 8")
    assert sesion.revocada is False
    encontrada = sesion_repository.obtener_por_hash_token(connection, "hash-token")
    assert encontrada.id == sesion.id


def test_revocar_guarda_el_motivo(connection):
    usuario = usuario_repository.crear(connection, "alex", "hash-falso")
    sesion = sesion_repository.crear(connection, usuario.id, "hash-token", "Pixel 8")
    sesion_repository.revocar(connection, sesion.id, "desemparejado")
    revocada = sesion_repository.obtener_por_hash_token(connection, "hash-token")
    assert revocada.revocada is True
    assert revocada.motivo_revocacion == "desemparejado"


def test_revocar_todas_de_usuario_no_toca_las_de_otro(connection):
    alex = usuario_repository.crear(connection, "alex", "hash-falso")
    otro = usuario_repository.crear(connection, "otro", "hash-falso")
    sesion_alex = sesion_repository.crear(connection, alex.id, "token-alex", "Pixel 8")
    sesion_otro = sesion_repository.crear(connection, otro.id, "token-otro", "iPhone")

    sesion_repository.revocar_todas_de_usuario(connection, alex.id, "cerrar_todas")

    assert sesion_repository.obtener_por_hash_token(connection, "token-alex").revocada is True
    assert sesion_repository.obtener_por_hash_token(connection, "token-otro").revocada is False


def test_tocar_ultimo_acceso_lo_cambia(connection):
    usuario = usuario_repository.crear(connection, "alex", "hash-falso")
    sesion = sesion_repository.crear(connection, usuario.id, "hash-token", "Pixel 8")
    sesion_repository.tocar_ultimo_acceso(connection, sesion.id)
    actualizada = sesion_repository.obtener_por_hash_token(connection, "hash-token")
    assert actualizada.ultimo_acceso >= sesion.ultimo_acceso


def test_intento_login_se_registra_y_se_lista(connection):
    usuario = usuario_repository.crear(connection, "alex", "hash-falso")
    intento_login_repository.registrar(connection, usuario.id, "alex", "local", exito=False)
    intento_login_repository.registrar(connection, usuario.id, "alex", "local", exito=True)

    intentos = intento_login_repository.listar_de_usuario(connection, "alex")
    assert [i.exito for i in intentos] == [False, True]


def test_borrar_de_usuario_quita_sus_intentos(connection):
    intento_login_repository.registrar(connection, None, "alex", "local", exito=False)
    intento_login_repository.borrar_de_usuario(connection, "alex")
    assert intento_login_repository.listar_de_usuario(connection, "alex") == []


def test_solicitud_login_se_crea_pendiente_y_se_obtiene(connection):
    usuario = usuario_repository.crear(connection, "alex", "hash-falso")
    solicitud_login_repository.crear(connection, "id-aleatorio", usuario.id, "Pixel 8", caduca_en="2030-01-01T00:00:00+00:00")

    encontrada = solicitud_login_repository.obtener(connection, "id-aleatorio")
    assert encontrada.estado == "pendiente"


def test_actualizar_estado_de_solicitud(connection):
    usuario = usuario_repository.crear(connection, "alex", "hash-falso")
    solicitud_login_repository.crear(connection, "id-aleatorio", usuario.id, "Pixel 8", caduca_en="2030-01-01T00:00:00+00:00")

    solicitud_login_repository.actualizar_estado(connection, "id-aleatorio", "aprobada")

    assert solicitud_login_repository.obtener(connection, "id-aleatorio").estado == "aprobada"


def test_borrar_solicitud(connection):
    usuario = usuario_repository.crear(connection, "alex", "hash-falso")
    solicitud_login_repository.crear(connection, "id-aleatorio", usuario.id, "Pixel 8", caduca_en="2030-01-01T00:00:00+00:00")
    solicitud_login_repository.borrar(connection, "id-aleatorio")
    assert solicitud_login_repository.obtener(connection, "id-aleatorio") is None
