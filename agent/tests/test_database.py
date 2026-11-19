"""Conexión a SQLite: permisos del archivo, claves foráneas activas y cuenta única."""

import sqlite3
import stat

import pytest

from sysmote import database, rutas
from sysmote.repositories import usuario_repository


def test_connect_crea_archivo_y_directorio_con_permisos_seguros():
    connection = database.connect()
    connection.close()

    assert stat.S_IMODE(rutas.DB_PATH.stat().st_mode) == 0o600
    assert stat.S_IMODE(rutas.DB_PATH.parent.stat().st_mode) == 0o700


def test_connect_activa_claves_foraneas():
    connection = database.connect()
    assert connection.execute("PRAGMA foreign_keys").fetchone() == (1,)
    connection.close()


def test_la_base_de_datos_solo_admite_una_cuenta(connection):
    usuario_repository.crear(connection, "alex", "hash-falso")

    with pytest.raises(sqlite3.IntegrityError):
        usuario_repository.crear(connection, "otro", "hash-falso")
