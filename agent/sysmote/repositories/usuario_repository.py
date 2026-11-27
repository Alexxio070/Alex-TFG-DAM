"""Acceso a la tabla `usuario`: la cuenta del agente (en la práctica, solo hay una)."""

import sqlite3
from datetime import UTC, datetime

from sysmote.models.auth import Usuario

_COLUMNS = "id, nombre_usuario, hash_contrasena, creado_en"


def _to_usuario(row: tuple) -> Usuario:
    return Usuario(id=row[0], nombre_usuario=row[1], hash_contrasena=row[2], creado_en=row[3])


def crear(connection: sqlite3.Connection, nombre_usuario: str, hash_contrasena: str) -> Usuario:
    """Crea la cuenta con el hash de su contraseña (nunca la contraseña en claro)."""
    creado_en = datetime.now(UTC).isoformat()
    cursor = connection.execute(
        "INSERT INTO usuario (nombre_usuario, hash_contrasena, creado_en) VALUES (?, ?, ?)",
        (nombre_usuario, hash_contrasena, creado_en),
    )
    connection.commit()
    return Usuario(
        id=cursor.lastrowid,
        nombre_usuario=nombre_usuario,
        hash_contrasena=hash_contrasena,
        creado_en=creado_en,
    )


def obtener_por_nombre(connection: sqlite3.Connection, nombre_usuario: str) -> Usuario | None:
    """Busca la cuenta por su nombre de usuario."""
    row = connection.execute(
        f"SELECT {_COLUMNS} FROM usuario WHERE nombre_usuario = ?", (nombre_usuario,)
    ).fetchone()
    return _to_usuario(row) if row else None


def obtener_primero(connection: sqlite3.Connection) -> Usuario | None:
    """Devuelve la cuenta del agente; la TUI la usa porque no pide el nombre de usuario."""
    row = connection.execute(f"SELECT {_COLUMNS} FROM usuario ORDER BY id LIMIT 1").fetchone()
    return _to_usuario(row) if row else None


def obtener_por_id(connection: sqlite3.Connection, usuario_id: int) -> Usuario | None:
    """Busca la cuenta por su id."""
    row = connection.execute(
        f"SELECT {_COLUMNS} FROM usuario WHERE id = ?", (usuario_id,)
    ).fetchone()
    return _to_usuario(row) if row else None


def existe_alguno(connection: sqlite3.Connection) -> bool:
    """Indica si el agente ya está configurado (tiene cuenta)."""
    return connection.execute("SELECT 1 FROM usuario LIMIT 1").fetchone() is not None


def actualizar_contrasena(
    connection: sqlite3.Connection, usuario_id: int, hash_contrasena: str
) -> None:
    """Sustituye el hash de la contraseña."""
    connection.execute(
        "UPDATE usuario SET hash_contrasena = ? WHERE id = ?", (hash_contrasena, usuario_id)
    )
    connection.commit()
