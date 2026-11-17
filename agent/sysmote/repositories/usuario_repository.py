import sqlite3
from datetime import UTC, datetime

from sysmote.models.auth import Usuario


def crear(connection: sqlite3.Connection, nombre_usuario: str, hash_contrasena: str) -> Usuario:
    creado_en = datetime.now(UTC).isoformat()
    cursor = connection.execute(
        "INSERT INTO usuario (nombre_usuario, hash_contrasena, creado_en) VALUES (?, ?, ?)",
        (nombre_usuario, hash_contrasena, creado_en),
    )
    connection.commit()
    return Usuario(id=cursor.lastrowid, nombre_usuario=nombre_usuario, hash_contrasena=hash_contrasena, creado_en=creado_en)


def obtener_por_nombre(connection: sqlite3.Connection, nombre_usuario: str) -> Usuario | None:
    row = connection.execute(
        "SELECT id, nombre_usuario, hash_contrasena, creado_en FROM usuario WHERE nombre_usuario = ?",
        (nombre_usuario,),
    ).fetchone()
    return Usuario(id=row[0], nombre_usuario=row[1], hash_contrasena=row[2], creado_en=row[3]) if row else None


def obtener_por_id(connection: sqlite3.Connection, usuario_id: int) -> Usuario | None:
    row = connection.execute(
        "SELECT id, nombre_usuario, hash_contrasena, creado_en FROM usuario WHERE id = ?", (usuario_id,)
    ).fetchone()
    return Usuario(id=row[0], nombre_usuario=row[1], hash_contrasena=row[2], creado_en=row[3]) if row else None


def existe_alguno(connection: sqlite3.Connection) -> bool:
    return connection.execute("SELECT 1 FROM usuario LIMIT 1").fetchone() is not None


def actualizar_contrasena(connection: sqlite3.Connection, usuario_id: int, hash_contrasena: str) -> None:
    connection.execute(
        "UPDATE usuario SET hash_contrasena = ? WHERE id = ?", (hash_contrasena, usuario_id)
    )
    connection.commit()
