"""Modelos de autenticación: una clase por tabla de `schema.sql` y los cuerpos de las peticiones."""

from pydantic import BaseModel, Field

DISPOSITIVO_POR_DEFECTO = "Móvil"


class Usuario(BaseModel):
    """La cuenta del agente (solo existe una)."""

    id: int
    nombre_usuario: str
    hash_contrasena: str
    creado_en: str


class Sesion(BaseModel):
    """Una sesión de la app. Del token solo se guarda su hash; `motivo_revocacion` distingue el 401."""

    id: int
    usuario_id: int
    hash_token: str
    dispositivo: str
    creado_en: str
    ultimo_acceso: str
    revocada: bool
    motivo_revocacion: str | None


class IntentoLogin(BaseModel):
    """Un intento de login, correcto o no; sirve para el límite de intentos."""

    id: int
    usuario_id: int | None
    nombre_usuario: str
    origen: str
    fecha: str
    exito: bool


class SolicitudLogin(BaseModel):
    """Un login que espera confirmación en la TUI porque ya hay otra sesión activa."""

    id: str
    usuario_id: int
    dispositivo: str
    creada: str
    estado: str
    caduca_en: str


class CodigoRegistro(BaseModel):
    """El código de registro de un solo uso que genera la TUI (solo se guarda su hash)."""

    id: int
    hash_codigo: str
    creado: str
    caduca_en: str
    usado: bool


class RegistroRequest(BaseModel):
    """Cuerpo de `POST /registro`."""

    codigo: str = Field(min_length=1)
    usuario: str = Field(min_length=1)
    contrasena: str = Field(min_length=1)
    dispositivo: str = DISPOSITIVO_POR_DEFECTO


class LoginRequest(BaseModel):
    """Cuerpo de `POST /login`."""

    usuario: str = Field(min_length=1)
    contrasena: str = Field(min_length=1)
    dispositivo: str = DISPOSITIVO_POR_DEFECTO
