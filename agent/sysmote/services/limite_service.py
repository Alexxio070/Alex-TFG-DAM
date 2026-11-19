"""Límite de intentos de login (contrato, §5): 5 fallos seguidos bloquean la cuenta un tiempo.

Se limita por cuenta y no por IP, porque por iroh todas las conexiones llegan desde
`127.0.0.1`. La duración del bloqueo se configura en `config.toml` (`config_service`).
"""

import math
import sqlite3
from datetime import UTC, datetime, timedelta

from sysmote.models.auth import IntentoLogin
from sysmote.repositories import intento_login_repository
from sysmote.services import config_service
from sysmote.services.auth_error import AuthError

MAX_FALLOS = 5


def espera_restante(intentos: list[IntentoLogin], ahora: datetime, duracion: timedelta) -> int:
    """Calcula cuántos segundos quedan de bloqueo; 0 si la cuenta no está bloqueada.

    Recorre los intentos en orden: un acierto, o el final de un bloqueo, ponen el contador a
    cero, y el quinto fallo seguido bloquea durante `duracion` desde ese fallo.
    """
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
    """Deja pasar el login solo si la cuenta no está bloqueada.

    Raises:
        AuthError: `demasiados_intentos`, con los segundos de espera en `espera_s`.
    """
    intentos = intento_login_repository.listar_de_usuario(connection, nombre_usuario)
    espera = espera_restante(intentos, datetime.now(UTC), config_service.duracion_bloqueo())
    if espera:
        raise AuthError("demasiados_intentos", "Demasiados intentos fallidos", espera_s=espera)


def registrar(
    connection: sqlite3.Connection,
    nombre_usuario: str,
    usuario_id: int | None,
    origen: str,
    exito: bool,
) -> None:
    """Anota un intento de login, correcto o fallido."""
    intento_login_repository.registrar(connection, usuario_id, nombre_usuario, origen, exito)


def reiniciar(connection: sqlite3.Connection, nombre_usuario: str) -> None:
    """Borra los intentos de la cuenta, lo que también levanta el bloqueo."""
    intento_login_repository.borrar_de_usuario(connection, nombre_usuario)
