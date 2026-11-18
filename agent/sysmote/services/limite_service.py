import math
import sqlite3
from datetime import UTC, datetime, timedelta

from sysmote.models.auth import IntentoLogin
from sysmote.repositories import intento_login_repository
from sysmote.services import config_service
from sysmote.services.auth_error import AuthError

MAX_FALLOS = 5


def espera_restante(intentos: list[IntentoLogin], ahora: datetime, duracion: timedelta) -> int:
    fallos = 0
    bloqueado_hasta = None
    for intento in intentos:
        fecha = datetime.fromisoformat(intento.fecha)
        if bloqueado_hasta is not None and fecha >= bloqueado_hasta:
            fallos = 0
            bloqueado_hasta = None
        fallos = 0 if intento.exito else fallos + 1
        if fallos == MAX_FALLOS:
            bloqueado_hasta = fecha + duracion
    if bloqueado_hasta is None or ahora >= bloqueado_hasta:
        return 0
    return math.ceil((bloqueado_hasta - ahora).total_seconds())


def comprobar(connection: sqlite3.Connection, nombre_usuario: str) -> None:
    intentos = intento_login_repository.listar_recientes_de_usuario(connection, nombre_usuario, desde="")
    espera = espera_restante(intentos, datetime.now(UTC), config_service.duracion_bloqueo())
    if espera:
        raise AuthError("demasiados_intentos", "Demasiados intentos fallidos", espera_s=espera)


def registrar(
    connection: sqlite3.Connection, nombre_usuario: str, usuario_id: int | None, origen: str, exito: bool
) -> None:
    intento_login_repository.registrar(connection, usuario_id, nombre_usuario, origen, exito)


def reiniciar(connection: sqlite3.Connection, nombre_usuario: str) -> None:
    intento_login_repository.borrar_de_usuario(connection, nombre_usuario)
