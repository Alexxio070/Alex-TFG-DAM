import os
import sqlite3
from pathlib import Path

DB_PATH = Path.home() / ".local" / "share" / "sysmote" / "sysmote.db"
_SCHEMA_PATH = Path(__file__).resolve().parent.parent / "schema.sql"


def connect() -> sqlite3.Connection:
    DB_PATH.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(DB_PATH.parent, 0o700)
    if not DB_PATH.exists():
        # 0600 desde la creación: escribir primero y hacer chmod después deja
        # el archivo legible por otros usuarios durante unos instantes.
        os.close(os.open(DB_PATH, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600))
    # FastAPI puede ejecutar la dependencia y el endpoint en hilos distintos; cada
    # petición usa su propia conexión, así que no hay acceso concurrente.
    connection = sqlite3.connect(DB_PATH, check_same_thread=False)
    connection.execute("PRAGMA foreign_keys = ON")
    connection.executescript(_SCHEMA_PATH.read_text())
    return connection
