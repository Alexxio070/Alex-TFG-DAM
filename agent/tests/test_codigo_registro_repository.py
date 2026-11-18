import sqlite3
from pathlib import Path

import pytest

from sysmote.repositories import codigo_registro_repository

SCHEMA = (Path(__file__).resolve().parent.parent / "schema.sql").read_text()


@pytest.fixture
def connection():
    connection = sqlite3.connect(":memory:")
    connection.execute("PRAGMA foreign_keys = ON")
    connection.executescript(SCHEMA)
    yield connection
    connection.close()


def test_crear_y_obtener_por_hash(connection):
    codigo_registro_repository.crear(connection, "hash-1", caduca_en="2030-01-01T00:00:00+00:00")
    encontrado = codigo_registro_repository.obtener_por_hash(connection, "hash-1")
    assert encontrado.usado is False
    assert encontrado.caduca_en == "2030-01-01T00:00:00+00:00"


def test_obtener_por_hash_inexistente_devuelve_none(connection):
    assert codigo_registro_repository.obtener_por_hash(connection, "nada") is None


def test_existe_vigente_solo_si_no_usado_ni_caducado(connection):
    ahora = "2026-01-01T00:00:00+00:00"
    assert codigo_registro_repository.existe_vigente(connection, ahora) is False

    codigo_registro_repository.crear(connection, "h-caducado", caduca_en="2025-01-01T00:00:00+00:00")
    assert codigo_registro_repository.existe_vigente(connection, ahora) is False

    vigente = codigo_registro_repository.crear(connection, "h-vigente", caduca_en="2030-01-01T00:00:00+00:00")
    assert codigo_registro_repository.existe_vigente(connection, ahora) is True

    codigo_registro_repository.marcar_usado(connection, vigente.id)
    assert codigo_registro_repository.existe_vigente(connection, ahora) is False


def test_existe_alguno_cuenta_tambien_los_caducados_y_los_usados(connection):
    assert codigo_registro_repository.existe_alguno(connection) is False
    codigo_registro_repository.crear(connection, "h-caducado", caduca_en="2025-01-01T00:00:00+00:00")
    assert codigo_registro_repository.existe_alguno(connection) is True


def test_borrar_todos(connection):
    codigo_registro_repository.crear(connection, "hash-1", caduca_en="2030-01-01T00:00:00+00:00")
    codigo_registro_repository.borrar_todos(connection)
    assert codigo_registro_repository.obtener_por_hash(connection, "hash-1") is None
