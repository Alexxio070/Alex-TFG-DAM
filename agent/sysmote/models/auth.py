from pydantic import BaseModel


class Usuario(BaseModel):
    id: int
    nombre_usuario: str
    hash_contrasena: str
    creado_en: str


class Sesion(BaseModel):
    id: int
    usuario_id: int
    hash_token: str
    dispositivo: str
    creado_en: str
    ultimo_acceso: str
    revocada: bool
    motivo_revocacion: str | None


class IntentoLogin(BaseModel):
    id: int
    usuario_id: int | None
    nombre_usuario: str
    origen: str
    fecha: str
    exito: bool


class SolicitudLogin(BaseModel):
    id: str
    usuario_id: int
    dispositivo: str
    creada: str
    estado: str
    caduca_en: str


class CodigoRegistro(BaseModel):
    id: int
    hash_codigo: str
    creado: str
    caduca_en: str
    usado: bool
