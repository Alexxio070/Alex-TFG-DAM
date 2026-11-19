"""Rutas HTTP de autenticación y sesión (contrato de la fase 3, `doc/agente/contrato-api-fase3.md`).

Solo traducen HTTP a llamadas a `auth_service`: la lógica vive en el servicio. Las rutas de
`publico` responden sin sesión; las de `protegido` exigen un token válido.
"""

import sqlite3

from fastapi import APIRouter, Depends, Request, Response
from fastapi.responses import JSONResponse

from sysmote.api.deps import get_connection, requiere_sesion
from sysmote.models.auth import LoginRequest, RegistroRequest, Sesion
from sysmote.services import auth_service

publico = APIRouter()
protegido = APIRouter(dependencies=[Depends(requiere_sesion)])


@publico.get("/estado")
def get_estado(connection: sqlite3.Connection = Depends(get_connection)) -> dict:
    """Devuelve si el agente ya tiene cuenta, si el registro está abierto y si hay una sesión activa."""
    return auth_service.estado(connection)


@publico.post("/registro", status_code=201)
def post_registro(
    datos: RegistroRequest, connection: sqlite3.Connection = Depends(get_connection)
) -> dict:
    """Crea la única cuenta del agente con el código de registro de la TUI y abre ya una sesión."""
    return auth_service.registrar(
        connection, datos.codigo, datos.usuario, datos.contrasena, datos.dispositivo
    )


@publico.post("/login")
def post_login(
    datos: LoginRequest, request: Request, connection: sqlite3.Connection = Depends(get_connection)
) -> JSONResponse:
    """Inicia sesión: 200 con el token, o 202 con una solicitud pendiente si ya hay otra sesión activa."""
    origen = request.client.host if request.client else "desconocido"
    resultado = auth_service.login(
        connection, datos.usuario, datos.contrasena, datos.dispositivo, origen
    )
    return JSONResponse(status_code=202 if "solicitud" in resultado else 200, content=resultado)


@publico.get("/login/solicitud/{solicitud_id}")
def get_solicitud(
    solicitud_id: str, connection: sqlite3.Connection = Depends(get_connection)
) -> dict:
    """Consulta qué ha decidido el usuario en la TUI sobre una solicitud de login pendiente."""
    return auth_service.consultar_solicitud(connection, solicitud_id)


@protegido.post("/logout", status_code=204)
def post_logout(
    sesion: Sesion = Depends(requiere_sesion),
    connection: sqlite3.Connection = Depends(get_connection),
) -> Response:
    """Cierra la sesión del token de la petición; el emparejamiento se mantiene."""
    auth_service.cerrar_sesion(connection, sesion)
    return Response(status_code=204)


@protegido.post("/desemparejar", status_code=204)
def post_desemparejar(
    sesion: Sesion = Depends(requiere_sesion),
    connection: sqlite3.Connection = Depends(get_connection),
) -> Response:
    """Cierra la sesión y la marca como desemparejada: la app olvida el equipo."""
    auth_service.desemparejar(connection, sesion)
    return Response(status_code=204)


@protegido.get("/sesion")
def get_sesion(
    sesion: Sesion = Depends(requiere_sesion),
    connection: sqlite3.Connection = Depends(get_connection),
) -> dict:
    """Comprueba que el token sigue valiendo y devuelve el usuario, el dispositivo y la fecha de la sesión."""
    return auth_service.datos_sesion(connection, sesion)


@protegido.get("/capacidades")
def get_capacidades() -> dict:
    """Lista los módulos que el agente tiene implementados, para que la app sepa cuáles usar."""
    return {"modulos": ["metricas"]}
