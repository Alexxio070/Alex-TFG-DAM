"""Acceso a la tabla `sesion`: las sesiones de la app, identificadas por el hash de su token."""

import sqlite3
from datetime import UTC, datetime

from sysmote.models.auth import Sesion

_COLUMNS = "id, usuario_id, hash_token, dispositivo, creado_en, ultimo_acceso, revocada, motivo_revocacion"


def _to_sesion(row: tuple) -> Sesion:
    return Sesion(
        id=row[0],
        usuario_id=row[1],
        hash_token=row[2],
        dispositivo=row[3],
        creado_en=row[4],
        ultimo_acceso=row[5],
        revocada=bool(row[6]),
        motivo_revocacion=row[7],
    )


def crear(connection: sqlite3.Connection, usuario_id: int, hash_token: str, dispositivo: str) -> Sesion:
    """Crea una sesión sin revocar, con la fecha actual como creación y último acceso."""
    ahora = datetime.now(UTC).isoformat()
    cursor = connection.execute(
        "INSERT INTO sesion (usuario_id, hash_token, dispositivo, creado_en, ultimo_acceso) "
        "VALUES (?, ?, ?, ?, ?)",
        (usuario_id, hash_token, dispositivo, ahora, ahora),
    )
    connection.commit()
    return Sesion(
        id=cursor.lastrowid,
        usuario_id=usuario_id,
        hash_token=hash_token,
        dispositivo=dispositivo,
        creado_en=ahora,
        ultimo_acceso=ahora,
        revocada=False,
        motivo_revocacion=None,
    )


def obtener_por_hash_token(connection: sqlite3.Connection, hash_token: str) -> Sesion | None:
    """Busca la sesión de un token (por su hash), esté o no revocada."""
    row = connection.execute(
        f"SELECT {_COLUMNS} FROM sesion WHERE hash_token = ?", (hash_token,)
    ).fetchone()
    return _to_sesion(row) if row else None


def obtener_activa(connection: sqlite3.Connection) -> Sesion | None:
    """Devuelve la sesión sin revocar más reciente; no comprueba si ha caducado por inactividad."""
    row = connection.execute(
        f"SELECT {_COLUMNS} FROM sesion WHERE revocada = 0 ORDER BY id DESC LIMIT 1"
    ).fetchone()
    return _to_sesion(row) if row else None


def tocar_ultimo_acceso(connection: sqlite3.Connection, sesion_id: int) -> None:
    """Pone el último acceso a ahora: cada uso renueva los 30 días de caducidad."""
    connection.execute(
        "UPDATE sesion SET ultimo_acceso = ? WHERE id = ?", (datetime.now(UTC).isoformat(), sesion_id)
    )
    connection.commit()


def revocar(connection: sqlite3.Connection, sesion_id: int, motivo: str) -> None:
    """Revoca una sesión guardando el motivo (por ejemplo `logout` o `desemparejado`)."""
    connection.execute(
        "UPDATE sesion SET revocada = 1, motivo_revocacion = ? WHERE id = ?", (motivo, sesion_id)
    )
    connection.commit()


def revocar_todas_de_usuario(connection: sqlite3.Connection, usuario_id: int, motivo: str) -> None:
    """Revoca todas las sesiones abiertas de un usuario."""
    connection.execute(
        "UPDATE sesion SET revocada = 1, motivo_revocacion = ? WHERE usuario_id = ? AND revocada = 0",
        (motivo, usuario_id),
    )
    connection.commit()
