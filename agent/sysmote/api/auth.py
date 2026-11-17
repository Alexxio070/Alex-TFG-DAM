import sqlite3

from fastapi import APIRouter, Depends, Response
from fastapi.responses import JSONResponse

from sysmote.api.deps import get_connection, requiere_sesion
from sysmote.models.auth import LoginRequest, RegistroRequest, Sesion
from sysmote.repositories import usuario_repository
from sysmote.services import auth_service

publico = APIRouter()
protegido = APIRouter(dependencies=[Depends(requiere_sesion)])


@publico.get("/estado")
def get_estado(connection: sqlite3.Connection = Depends(get_connection)) -> dict:
    return auth_service.estado(connection)


@publico.post("/registro", status_code=201)
def post_registro(datos: RegistroRequest, connection: sqlite3.Connection = Depends(get_connection)) -> dict:
    return auth_service.registrar(connection, datos.codigo, datos.usuario, datos.contrasena, datos.dispositivo)


@publico.post("/login")
def post_login(datos: LoginRequest, connection: sqlite3.Connection = Depends(get_connection)) -> JSONResponse:
    resultado = auth_service.login(connection, datos.usuario, datos.contrasena, datos.dispositivo)
    return JSONResponse(status_code=202 if "solicitud" in resultado else 200, content=resultado)


@publico.get("/login/solicitud/{solicitud_id}")
def get_solicitud(solicitud_id: str, connection: sqlite3.Connection = Depends(get_connection)) -> dict:
    return auth_service.consultar_solicitud(connection, solicitud_id)


@protegido.post("/logout", status_code=204)
def post_logout(
    sesion: Sesion = Depends(requiere_sesion), connection: sqlite3.Connection = Depends(get_connection)
) -> Response:
    auth_service.cerrar_sesion(connection, sesion)
    return Response(status_code=204)


@protegido.post("/desemparejar", status_code=204)
def post_desemparejar(
    sesion: Sesion = Depends(requiere_sesion), connection: sqlite3.Connection = Depends(get_connection)
) -> Response:
    auth_service.desemparejar(connection, sesion)
    return Response(status_code=204)


@protegido.get("/sesion")
def get_sesion(
    sesion: Sesion = Depends(requiere_sesion), connection: sqlite3.Connection = Depends(get_connection)
) -> dict:
    cuenta = usuario_repository.obtener_por_id(connection, sesion.usuario_id)
    return {"usuario": cuenta.nombre_usuario, "dispositivo": sesion.dispositivo, "creada": sesion.creado_en}


@protegido.get("/capacidades")
def get_capacidades() -> dict:
    return {"modulos": ["metricas"]}
