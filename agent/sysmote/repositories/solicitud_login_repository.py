"""Acceso a la tabla `solicitud_login`: los logins que esperan confirmación en la TUI.

La TUI y la API no se hablan directamente: se comunican a través de esta tabla.
"""

import sqlite3
from datetime import UTC, datetime

from sysmote.models.auth import SolicitudLogin

_COLUMNS = "id, usuario_id, dispositivo, creada, estado, caduca_en"


def _to_solicitud(row: tuple) -> SolicitudLogin:
    return SolicitudLogin(id=row[0], usuario_id=row[1], dispositivo=row[2], creada=row[3], estado=row[4], caduca_en=row[5])


def crear(
    connection: sqlite3.Connection, id: str, usuario_id: int, dispositivo: str, caduca_en: str
) -> SolicitudLogin:
    """Crea una solicitud en estado `pendiente`. `id` es el valor aleatorio que recibe la app."""
    creada = datetime.now(UTC).isoformat()
    connection.execute(
        "INSERT INTO solicitud_login (id, usuario_id, dispositivo, creada, estado, caduca_en) "
        "VALUES (?, ?, ?, ?, 'pendiente', ?)",
        (id, usuario_id, dispositivo, creada, caduca_en),
    )
    connection.commit()
    return SolicitudLogin(id=id, usuario_id=usuario_id, dispositivo=dispositivo, creada=creada, estado="pendiente", caduca_en=caduca_en)


def obtener(connection: sqlite3.Connection, id: str) -> SolicitudLogin | None:
    """Busca una solicitud por su id."""
    row = connection.execute(f"SELECT {_COLUMNS} FROM solicitud_login WHERE id = ?", (id,)).fetchone()
    return _to_solicitud(row) if row else None


def obtener_pendiente(connection: sqlite3.Connection) -> SolicitudLogin | None:
    """Devuelve la solicitud pendiente más reciente; no comprueba si ha caducado."""
    row = connection.execute(
        f"SELECT {_COLUMNS} FROM solicitud_login WHERE estado = 'pendiente' ORDER BY creada DESC LIMIT 1"
    ).fetchone()
    return _to_solicitud(row) if row else None


def actualizar_estado(connection: sqlite3.Connection, id: str, estado: str) -> None:
    """Cambia el estado: `pendiente`, `aprobada`, `rechazada` o `caducada`."""
    connection.execute("UPDATE solicitud_login SET estado = ? WHERE id = ?", (estado, id))
    connection.commit()


def borrar(connection: sqlite3.Connection, id: str) -> None:
    """Borra una solicitud (tras entregar su token una vez)."""
    connection.execute("DELETE FROM solicitud_login WHERE id = ?", (id,))
    connection.commit()


def borrar_de_usuario(connection: sqlite3.Connection, usuario_id: int) -> None:
    """Borra todas las solicitudes de un usuario: un login nuevo sustituye a la anterior."""
    connection.execute("DELETE FROM solicitud_login WHERE usuario_id = ?", (usuario_id,))
    connection.commit()
