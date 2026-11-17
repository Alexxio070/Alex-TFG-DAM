import sqlite3
from datetime import UTC, datetime

from sysmote.models.auth import CodigoRegistro

_COLUMNS = "id, hash_codigo, creado, caduca_en, usado"


def _to_codigo(row: tuple) -> CodigoRegistro:
    return CodigoRegistro(id=row[0], hash_codigo=row[1], creado=row[2], caduca_en=row[3], usado=bool(row[4]))


def crear(connection: sqlite3.Connection, hash_codigo: str, caduca_en: str) -> CodigoRegistro:
    creado = datetime.now(UTC).isoformat()
    cursor = connection.execute(
        "INSERT INTO codigo_registro (hash_codigo, creado, caduca_en) VALUES (?, ?, ?)",
        (hash_codigo, creado, caduca_en),
    )
    connection.commit()
    return CodigoRegistro(id=cursor.lastrowid, hash_codigo=hash_codigo, creado=creado, caduca_en=caduca_en, usado=False)


def obtener_por_hash(connection: sqlite3.Connection, hash_codigo: str) -> CodigoRegistro | None:
    row = connection.execute(
        f"SELECT {_COLUMNS} FROM codigo_registro WHERE hash_codigo = ?", (hash_codigo,)
    ).fetchone()
    return _to_codigo(row) if row else None


def existe_vigente(connection: sqlite3.Connection, ahora: str) -> bool:
    row = connection.execute(
        "SELECT 1 FROM codigo_registro WHERE usado = 0 AND caduca_en > ? LIMIT 1", (ahora,)
    ).fetchone()
    return row is not None


def marcar_usado(connection: sqlite3.Connection, codigo_id: int) -> None:
    connection.execute("UPDATE codigo_registro SET usado = 1 WHERE id = ?", (codigo_id,))
    connection.commit()


def borrar_todos(connection: sqlite3.Connection) -> None:
    connection.execute("DELETE FROM codigo_registro")
    connection.commit()
