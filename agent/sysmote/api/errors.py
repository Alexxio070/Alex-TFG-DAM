from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from sysmote.services.auth_service import AuthError

_ESTADO_DE_AUTH = {
    "no_autenticado": 401,
    "desemparejado": 401,
    "credenciales_invalidas": 401,
    "codigo_invalido": 403,
    "registro_cerrado": 403,
    "contrasena_debil": 422,
    "solicitud_desconocida": 404,
}
_CODIGO_DE_HTTP = {404: "no_encontrado", 405: "metodo_no_permitido"}


def _respuesta(estado: int, error: str, mensaje: str, **extra) -> JSONResponse:
    return JSONResponse(status_code=estado, content={"error": error, "mensaje": mensaje, **extra})


def registrar_manejadores(app: FastAPI) -> None:
    @app.exception_handler(AuthError)
    async def _auth(request: Request, exc: AuthError) -> JSONResponse:
        return _respuesta(_ESTADO_DE_AUTH[exc.codigo], exc.codigo, exc.mensaje, **exc.extra)

    @app.exception_handler(RequestValidationError)
    async def _validacion(request: Request, exc: RequestValidationError) -> JSONResponse:
        return _respuesta(422, "peticion_invalida", "La petición no es válida")

    @app.exception_handler(StarletteHTTPException)
    async def _http(request: Request, exc: StarletteHTTPException) -> JSONResponse:
        return _respuesta(exc.status_code, _CODIGO_DE_HTTP.get(exc.status_code, "error_http"), str(exc.detail))

    @app.exception_handler(Exception)
    async def _interno(request: Request, exc: Exception) -> JSONResponse:
        return _respuesta(500, "error_interno", "Error interno del agente")
