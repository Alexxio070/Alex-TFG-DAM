import sqlite3
from datetime import UTC, datetime

from sysmote.models.auth import SolicitudLogin

_COLUMNS = "id, usuario_id, dispositivo, creada, estado, caduca_en"


def _to_solicitud(row: tuple) -> SolicitudLogin:
    return SolicitudLogin(id=row[0], usuario_id=row[1], dispositivo=row[2], creada=row[3], estado=row[4], caduca_en=row[5])


def crear(
    connection: sqlite3.Connection, id: str, usuario_id: int, dispositivo: str, caduca_en: str
) -> SolicitudLogin:
    creada = datetime.now(UTC).isoformat()
    connection.execute(
        "INSERT INTO solicitud_login (id, usuario_id, dispositivo, creada, estado, caduca_en) "
        "VALUES (?, ?, ?, ?, 'pendiente', ?)",
        (id, usuario_id, dispositivo, creada, caduca_en),
    )
    connection.commit()
    return SolicitudLogin(id=id, usuario_id=usuario_id, dispositivo=dispositivo, creada=creada, estado="pendiente", caduca_en=caduca_en)


def obtener(connection: sqlite3.Connection, id: str) -> SolicitudLogin | None:
    row = connection.execute(f"SELECT {_COLUMNS} FROM solicitud_login WHERE id = ?", (id,)).fetchone()
    return _to_solicitud(row) if row else None


def obtener_pendiente_de_usuario(connection: sqlite3.Connection, usuario_id: int) -> SolicitudLogin | None:
    row = connection.execute(
        f"SELECT {_COLUMNS} FROM solicitud_login WHERE usuario_id = ? AND estado = 'pendiente'",
        (usuario_id,),
    ).fetchone()
    return _to_solicitud(row) if row else None


def obtener_pendiente(connection: sqlite3.Connection) -> SolicitudLogin | None:
    row = connection.execute(
        f"SELECT {_COLUMNS} FROM solicitud_login WHERE estado = 'pendiente' ORDER BY creada DESC LIMIT 1"
    ).fetchone()
    return _to_solicitud(row) if row else None


def actualizar_estado(connection: sqlite3.Connection, id: str, estado: str) -> None:
    connection.execute("UPDATE solicitud_login SET estado = ? WHERE id = ?", (estado, id))
    connection.commit()


def borrar(connection: sqlite3.Connection, id: str) -> None:
    connection.execute("DELETE FROM solicitud_login WHERE id = ?", (id,))
    connection.commit()


def borrar_de_usuario(connection: sqlite3.Connection, usuario_id: int) -> None:
    connection.execute("DELETE FROM solicitud_login WHERE usuario_id = ?", (usuario_id,))
    connection.commit()
