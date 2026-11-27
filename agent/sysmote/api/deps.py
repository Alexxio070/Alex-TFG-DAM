"""Dependencias de FastAPI que comparten las rutas: la conexión a SQLite y la sesión del usuario."""

import sqlite3
from collections.abc import Iterator

from fastapi import Depends, Header

from sysmote import database
from sysmote.models.auth import Sesion
from sysmote.services import auth_service


def get_connection() -> Iterator[sqlite3.Connection]:
    """Abre una conexión a SQLite para la petición y la cierra al terminar."""
    connection = database.connect()
    try:
        yield connection
    finally:
        connection.close()


def requiere_sesion(
    authorization: str | None = Header(default=None),
    connection: sqlite3.Connection = Depends(get_connection),
) -> Sesion:
    """Devuelve la sesión del token `Authorization: Bearer <token>`.

    Raises:
        AuthError: si falta el token, no es válido, caducó (`sesion_caducada`) o fue revocado
            (la API responde 401).
    """
    esquema, _, token = (authorization or "").partition(" ")
    return auth_service.autenticar(connection, token if esquema.lower() == "bearer" else None)
