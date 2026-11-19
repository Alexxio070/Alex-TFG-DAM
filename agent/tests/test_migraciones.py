"""Versión del esquema y migraciones de las bases de datos que ya existen."""

import sqlite3

import pytest

from sysmote import database, migraciones, rutas
from sysmote.repositories import usuario_repository

ANADIR_APODO = (("ALTER TABLE usuario ADD COLUMN apodo TEXT",),)


def _columnas(connection, tabla):
    return {fila[1] for fila in connection.execute(f"PRAGMA table_info({tabla})")}


def _version(connection):
    return connection.execute("PRAGMA user_version").fetchone()[0]


def test_una_base_nueva_se_crea_con_la_version_actual_sin_ejecutar_migraciones(monkeypatch):
    monkeypatch.setattr(migraciones, "MIGRACIONES", ANADIR_APODO)

    connection = database.connect()

    assert _version(connection) == 2
    assert "apodo" not in _columnas(connection, "usuario")  # schema.sql ya es el esquema actual
    connection.close()


def test_una_base_anterior_a_las_migraciones_cuenta_como_version_1():
    database.connect().close()
    antigua = sqlite3.connect(rutas.DB_PATH)
    antigua.execute(
        "PRAGMA user_version = 0"
    )  # así quedaban las bases creadas antes de las migraciones
    antigua.close()

    connection = database.connect()

    assert _version(connection) == 1
    connection.close()


def test_una_migracion_pendiente_se_aplica_y_conserva_los_datos(monkeypatch):
    connection = database.connect()
    usuario_repository.crear(connection, "alex", "hash-falso")
    connection.close()
    monkeypatch.setattr(migraciones, "MIGRACIONES", ANADIR_APODO)

    connection = database.connect()

    assert "apodo" in _columnas(connection, "usuario")
    assert usuario_repository.obtener_por_nombre(connection, "alex").nombre_usuario == "alex"
    assert _version(connection) == 2
    connection.close()


def test_una_migracion_ya_aplicada_no_se_repite(monkeypatch):
    database.connect().close()
    monkeypatch.setattr(migraciones, "MIGRACIONES", ANADIR_APODO)
    database.connect().close()

    connection = database.connect()  # repetir la migración daría «duplicate column name»

    assert _version(connection) == 2
    connection.close()


def test_una_migracion_que_falla_se_deshace_entera(monkeypatch):
    database.connect().close()
    monkeypatch.setattr(
        migraciones,
        "MIGRACIONES",
        (("ALTER TABLE usuario ADD COLUMN x TEXT", "ALTER TABLE no_existe ADD COLUMN y TEXT"),),
    )

    with pytest.raises(sqlite3.OperationalError):
        database.connect()

    connection = sqlite3.connect(rutas.DB_PATH)
    assert "x" not in _columnas(connection, "usuario")
    assert _version(connection) == 1
    connection.close()


def test_una_base_de_una_version_mas_nueva_da_un_error_claro():
    database.connect().close()
    nueva = sqlite3.connect(rutas.DB_PATH)
    nueva.execute("PRAGMA user_version = 99")
    nueva.close()

    with pytest.raises(RuntimeError, match="versión más nueva"):
        database.connect()
