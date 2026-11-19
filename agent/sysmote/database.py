"""Conexión a la base de datos SQLite del agente, con el esquema de `schema.sql` aplicado.

La versión del esquema se guarda en la propia base de datos (`PRAGMA user_version`). Las bases
nuevas se crean con `schema.sql`; a las que ya existen se les aplican los cambios pendientes de
`migraciones.py`.
"""

import os
import sqlite3
from pathlib import Path

from sysmote import migraciones, rutas

_SCHEMA_PATH = Path(__file__).resolve().parent / "schema.sql"


def _version(connection: sqlite3.Connection) -> int:
    return connection.execute("PRAGMA user_version").fetchone()[0]


def _migrar(connection: sqlite3.Connection) -> None:
    """Lleva una base de datos que ya existía a la versión actual del esquema.

    Cada migración se aplica en su propia transacción: si falla, no queda a medias.

    Raises:
        RuntimeError: si la base de datos es de una versión más nueva que la de este agente.
    """
    actual = _version(connection)
    if actual > migraciones.version_esquema():
        raise RuntimeError(
            f"La base de datos es de una versión más nueva del agente (esquema {actual}; este agente "
            f"llega hasta el {migraciones.version_esquema()}). Actualiza el agente."
        )
    # Una base creada antes de que existieran las migraciones tiene user_version 0 y es la versión 1.
    for destino, sentencias in enumerate(migraciones.MIGRACIONES, start=2):
        if max(actual, 1) >= destino:
            continue
        connection.execute("BEGIN IMMEDIATE")
        try:
            # Otra conexión pudo aplicarla mientras esta esperaba el bloqueo.
            if _version(connection) < destino:
                for sentencia in sentencias:
                    connection.execute(sentencia)
                connection.execute(f"PRAGMA user_version = {destino}")
            connection.commit()
        except Exception:
            connection.rollback()
            raise
    connection.execute(f"PRAGMA user_version = {migraciones.version_esquema()}")


def connect() -> sqlite3.Connection:
    """Abre la base de datos, creándola con permisos 0600 si no existe, y la deja en el esquema actual.

    Una base nueva se crea con `schema.sql`; una que ya existía se migra primero y después se aplica
    `schema.sql`, que usa `CREATE ... IF NOT EXISTS` y por tanto solo añade lo que falte.
    """
    db_path = rutas.DB_PATH
    db_path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(db_path.parent, 0o700)
    if not db_path.exists():
        # 0600 desde la creación: escribir primero y hacer chmod después deja
        # el archivo legible por otros usuarios durante unos instantes.
        os.close(os.open(db_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600))
    # FastAPI puede ejecutar la dependencia y el endpoint en hilos distintos; cada
    # petición usa su propia conexión, así que no hay acceso concurrente.
    connection = sqlite3.connect(db_path, check_same_thread=False)
    try:
        connection.execute("PRAGMA foreign_keys = ON")
        es_nueva = connection.execute("SELECT 1 FROM sqlite_master LIMIT 1").fetchone() is None
        if not es_nueva:
            _migrar(connection)
        connection.executescript(_SCHEMA_PATH.read_text())
        if es_nueva:
            connection.execute(f"PRAGMA user_version = {migraciones.version_esquema()}")
    except Exception:
        connection.close()
        raise
    return connection
