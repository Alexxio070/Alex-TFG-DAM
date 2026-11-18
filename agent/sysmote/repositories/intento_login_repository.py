import sqlite3
from datetime import UTC, datetime

from sysmote.models.auth import IntentoLogin


def registrar(
    connection: sqlite3.Connection,
    usuario_id: int | None,
    nombre_usuario: str,
    origen: str,
    exito: bool,
) -> IntentoLogin:
    fecha = datetime.now(UTC).isoformat()
    cursor = connection.execute(
        "INSERT INTO intento_login (usuario_id, nombre_usuario, origen, fecha, exito) VALUES (?, ?, ?, ?, ?)",
        (usuario_id, nombre_usuario, origen, fecha, int(exito)),
    )
    connection.commit()
    return IntentoLogin(
        id=cursor.lastrowid,
        usuario_id=usuario_id,
        nombre_usuario=nombre_usuario,
        origen=origen,
        fecha=fecha,
        exito=exito,
    )


def listar_de_usuario(connection: sqlite3.Connection, nombre_usuario: str) -> list[IntentoLogin]:
    rows = connection.execute(
        "SELECT id, usuario_id, nombre_usuario, origen, fecha, exito FROM intento_login "
        "WHERE nombre_usuario = ? ORDER BY fecha ASC",
        (nombre_usuario,),
    ).fetchall()
    return [
        IntentoLogin(id=r[0], usuario_id=r[1], nombre_usuario=r[2], origen=r[3], fecha=r[4], exito=bool(r[5]))
        for r in rows
    ]


def borrar_de_usuario(connection: sqlite3.Connection, nombre_usuario: str) -> None:
    connection.execute("DELETE FROM intento_login WHERE nombre_usuario = ?", (nombre_usuario,))
    connection.commit()
