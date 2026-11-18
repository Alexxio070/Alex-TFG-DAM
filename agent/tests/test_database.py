"""Conexión a SQLite: permisos del archivo y claves foráneas activas."""

import stat

from sysmote import database, rutas


def test_connect_crea_archivo_y_directorio_con_permisos_seguros():
    connection = database.connect()
    connection.close()

    assert stat.S_IMODE(rutas.DB_PATH.stat().st_mode) == 0o600
    assert stat.S_IMODE(rutas.DB_PATH.parent.stat().st_mode) == 0o700


def test_connect_activa_claves_foraneas():
    connection = database.connect()
    assert connection.execute("PRAGMA foreign_keys").fetchone() == (1,)
    connection.close()
