"""Versión del esquema y migraciones de las bases de datos que ya existen."""

import sqlite3
from datetime import UTC, datetime, timedelta

import pytest

from sysmote import database, migraciones, rutas
from sysmote.repositories import usuario_repository
from sysmote.services import auth_service, token_service
from sysmote.services.auth_service import AuthError

ANADIR_APODO = (("ALTER TABLE usuario ADD COLUMN apodo TEXT",),)

# Las dos tablas que la migración 1 toca, tal como estaban en el esquema 1 (sin `caduca_en`).
ESQUEMA_1 = """
CREATE TABLE usuario (
    id INTEGER PRIMARY KEY,
    nombre_usuario TEXT NOT NULL UNIQUE,
    hash_contrasena TEXT NOT NULL,
    creado_en TEXT NOT NULL
);
CREATE TABLE sesion (
    id INTEGER PRIMARY KEY,
    usuario_id INTEGER NOT NULL REFERENCES usuario(id),
    hash_token TEXT NOT NULL UNIQUE,
    dispositivo TEXT NOT NULL,
    creado_en TEXT NOT NULL,
    ultimo_acceso TEXT NOT NULL,
    revocada INTEGER NOT NULL DEFAULT 0,
    motivo_revocacion TEXT
);
"""


def _columnas(connection, tabla):
    return {fila[1] for fila in connection.execute(f"PRAGMA table_info({tabla})")}


def _version(connection):
    return connection.execute("PRAGMA user_version").fetchone()[0]


def _hace(dias):
    return (datetime.now(UTC) - timedelta(days=dias)).isoformat()


@pytest.fixture
def sin_migraciones(monkeypatch):
    """Las bases que crea `database.connect()` salen en la versión 1, como si no hubiera migraciones."""
    monkeypatch.setattr(migraciones, "MIGRACIONES", ())


def _crear_base_del_esquema_1(version_guardada, sesiones):
    """Crea en la carpeta temporal una base del esquema 1 con una cuenta y las sesiones dadas.

    Cada sesión es `(token, dias_desde_que_se_creo, motivo_revocacion)`.
    """
    rutas.DB_PATH.parent.mkdir(parents=True)
    base = sqlite3.connect(rutas.DB_PATH)
    base.executescript(ESQUEMA_1)
    base.execute("INSERT INTO usuario VALUES (1, 'alex', 'hash-falso', ?)", (_hace(30),))
    for token, dias, motivo in sesiones:
        creada = _hace(dias)
        base.execute(
            "INSERT INTO sesion (usuario_id, hash_token, dispositivo, creado_en, ultimo_acceso, "
            "revocada, motivo_revocacion) VALUES (1, ?, 'Pixel 8', ?, ?, ?, ?)",
            (token_service.hashear(token), creada, creada, int(motivo is not None), motivo),
        )
    base.execute(f"PRAGMA user_version = {version_guardada}")
    base.commit()
    base.close()


def test_una_base_nueva_se_crea_con_la_version_actual_sin_ejecutar_migraciones(monkeypatch):
    monkeypatch.setattr(migraciones, "MIGRACIONES", ANADIR_APODO)

    connection = database.connect()

    assert _version(connection) == 2
    assert "apodo" not in _columnas(connection, "usuario")  # schema.sql ya es el esquema actual
    connection.close()


def test_una_base_anterior_a_las_migraciones_cuenta_como_version_1(sin_migraciones):
    database.connect().close()
    antigua = sqlite3.connect(rutas.DB_PATH)
    antigua.execute(
        "PRAGMA user_version = 0"
    )  # así quedaban las bases creadas antes de las migraciones
    antigua.close()

    connection = database.connect()

    assert _version(connection) == 1
    connection.close()


def test_una_migracion_pendiente_se_aplica_y_conserva_los_datos(sin_migraciones, monkeypatch):
    connection = database.connect()
    usuario_repository.crear(connection, "alex", "hash-falso")
    connection.close()
    monkeypatch.setattr(migraciones, "MIGRACIONES", ANADIR_APODO)

    connection = database.connect()

    assert "apodo" in _columnas(connection, "usuario")
    assert usuario_repository.obtener_por_nombre(connection, "alex").nombre_usuario == "alex"
    assert _version(connection) == 2
    connection.close()


def test_una_migracion_ya_aplicada_no_se_repite(sin_migraciones, monkeypatch):
    database.connect().close()
    monkeypatch.setattr(migraciones, "MIGRACIONES", ANADIR_APODO)
    database.connect().close()

    connection = database.connect()  # repetir la migración daría «duplicate column name»

    assert _version(connection) == 2
    connection.close()


def test_una_migracion_que_falla_se_deshace_entera(sin_migraciones, monkeypatch):
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


def test_el_esquema_actual_es_el_2_y_una_base_nueva_ya_tiene_caduca_en():
    assert migraciones.version_esquema() == 2

    connection = database.connect()

    assert _version(connection) == 2
    columna = next(
        f for f in connection.execute("PRAGMA table_info(sesion)") if f[1] == "caduca_en"
    )
    assert columna[3] == 1  # NOT NULL
    connection.close()


@pytest.mark.parametrize("version_guardada", [0, 1], ids=["sin_user_version", "version_1"])
def test_la_migracion_1_da_a_cada_sesion_creado_en_mas_7_dias_y_no_toca_nada_mas(version_guardada):
    _crear_base_del_esquema_1(
        version_guardada,
        [("vigente", 2, None), ("vencida", 10, None), ("desemparejada", 3, "desemparejado")],
    )
    antes = sqlite3.connect(rutas.DB_PATH)
    filas_antes = antes.execute(
        "SELECT id, usuario_id, hash_token, dispositivo, creado_en, ultimo_acceso, revocada, "
        "motivo_revocacion FROM sesion ORDER BY id"
    ).fetchall()
    antes.close()

    connection = database.connect()

    assert _version(connection) == 2
    despues = connection.execute(
        "SELECT id, usuario_id, hash_token, dispositivo, creado_en, ultimo_acceso, revocada, "
        "motivo_revocacion, caduca_en FROM sesion ORDER BY id"
    ).fetchall()
    assert [fila[:-1] for fila in despues] == filas_antes  # historial intacto, sin borrar filas
    for fila in despues:
        creado_en, caduca_en = datetime.fromisoformat(fila[4]), datetime.fromisoformat(fila[-1])
        assert caduca_en.tzinfo is not None
        assert abs(caduca_en - creado_en - timedelta(days=7)) < timedelta(milliseconds=1)
    connection.close()


def test_tras_la_migracion_las_sesiones_ya_vencidas_fallan_y_las_vigentes_siguen():
    _crear_base_del_esquema_1(
        1,
        [("vigente", 2, None), ("vencida", 10, None), ("desemparejada", 3, "desemparejado")],
    )
    connection = database.connect()

    assert auth_service.autenticar(connection, "vigente").dispositivo == "Pixel 8"
    with pytest.raises(AuthError) as vencida:
        auth_service.autenticar(connection, "vencida")
    assert vencida.value.codigo == "sesion_caducada"
    with pytest.raises(AuthError) as desemparejada:
        auth_service.autenticar(connection, "desemparejada")
    assert desemparejada.value.codigo == "desemparejado"
    connection.close()
