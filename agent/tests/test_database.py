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


def test_connect_crea_las_cinco_tablas():
    connection = database.connect()
    tablas = {r[0] for r in connection.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    connection.close()
    assert tablas == {"usuario", "sesion", "intento_login", "solicitud_login", "codigo_registro"}


def test_connect_es_idempotente():
    database.connect().close()
    segunda = database.connect()
    assert segunda.execute("SELECT 1").fetchone() == (1,)
    segunda.close()
