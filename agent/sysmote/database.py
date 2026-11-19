"""Conexión a la base de datos SQLite del agente, con el esquema de `schema.sql` aplicado."""

import os
import sqlite3
from pathlib import Path

from sysmote import rutas

_SCHEMA_PATH = Path(__file__).resolve().parent / "schema.sql"


def connect() -> sqlite3.Connection:
    """Abre la base de datos, creándola con permisos 0600 si no existe, y aplica el esquema.

    El esquema usa `CREATE TABLE IF NOT EXISTS`, así que aplicarlo en cada conexión es inocuo.
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
    connection.execute("PRAGMA foreign_keys = ON")
    connection.executescript(_SCHEMA_PATH.read_text())
    return connection
