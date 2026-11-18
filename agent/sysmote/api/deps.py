import sqlite3
from collections.abc import Iterator

from fastapi import Depends, Header

from sysmote import database
from sysmote.models.auth import Sesion
from sysmote.services import auth_service


def get_connection() -> Iterator[sqlite3.Connection]:
    connection = database.connect()
    try:
        yield connection
    finally:
        connection.close()


def requiere_sesion(
    authorization: str | None = Header(default=None),
    connection: sqlite3.Connection = Depends(get_connection),
) -> Sesion:
    esquema, _, token = (authorization or "").partition(" ")
    return auth_service.autenticar(connection, token if esquema.lower() == "bearer" else None)
