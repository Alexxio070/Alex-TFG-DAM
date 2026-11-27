"""Acceso a la tabla `sesion`: las sesiones de la app, identificadas por el hash de su token."""

import sqlite3
from datetime import UTC, datetime

from sysmote.models.auth import Sesion

_COLUMNS = (
    "id, usuario_id, hash_token, dispositivo, creado_en, caduca_en, ultimo_acceso, "
    "revocada, motivo_revocacion"
)


def _to_sesion(row: tuple) -> Sesion:
    return Sesion(
        id=row[0],
        usuario_id=row[1],
        hash_token=row[2],
        dispositivo=row[3],
        creado_en=row[4],
        caduca_en=row[5],
        ultimo_acceso=row[6],
        revocada=bool(row[7]),
        motivo_revocacion=row[8],
    )


def crear(
    connection: sqlite3.Connection,
    usuario_id: int,
    hash_token: str,
    dispositivo: str,
    creado_en: str,
    caduca_en: str,
) -> Sesion:
    """Crea una sesión sin revocar; su último acceso es el momento de creación.

    Las fechas las calcula el servicio (ISO 8601 en UTC), que es quien decide cuánto dura.
    """
    cursor = connection.execute(
        "INSERT INTO sesion (usuario_id, hash_token, dispositivo, creado_en, caduca_en, "
        "ultimo_acceso) VALUES (?, ?, ?, ?, ?, ?)",
        (usuario_id, hash_token, dispositivo, creado_en, caduca_en, creado_en),
    )
    connection.commit()
    return Sesion(
        id=cursor.lastrowid,
        usuario_id=usuario_id,
        hash_token=hash_token,
        dispositivo=dispositivo,
        creado_en=creado_en,
        caduca_en=caduca_en,
        ultimo_acceso=creado_en,
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
        "UPDATE sesion SET ultimo_acceso = ? WHERE id = ?",
        (datetime.now(UTC).isoformat(), sesion_id),
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
