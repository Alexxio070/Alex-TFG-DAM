import hashlib
import secrets
import sqlite3
from datetime import UTC, datetime, timedelta

from sysmote.models.auth import Sesion
from sysmote.repositories import (
    codigo_registro_repository,
    sesion_repository,
    solicitud_login_repository,
    usuario_repository,
)
from sysmote.services import limite_service, password_service, token_service
from sysmote.services.auth_error import AuthError

API_VERSION = 1
CADUCIDAD_SOLICITUD = timedelta(minutes=5)
DISPOSITIVO_POR_DEFECTO = "Móvil"


def _ahora() -> datetime:
    return datetime.now(UTC)


def _sesion_vigente(sesion: Sesion | None) -> Sesion | None:
    if sesion is None or token_service.esta_caducada(sesion.ultimo_acceso):
        return None
    return sesion


def _sesion_activa_vigente(connection: sqlite3.Connection) -> Sesion | None:
    return _sesion_vigente(sesion_repository.obtener_activa(connection))


def _abrir_sesion(connection: sqlite3.Connection, usuario_id: int, dispositivo: str) -> str:
    anterior = sesion_repository.obtener_activa(connection)
    if anterior is not None:
        sesion_repository.revocar(connection, anterior.id, "caducada")
    token = token_service.generar()
    sesion_repository.crear(connection, usuario_id, token_service.hashear(token), dispositivo)
    return token


def motivos_contrasena_debil(contrasena: str) -> list[str]:
    motivos = []
    if len(contrasena) < 5:
        motivos.append("Debe tener al menos 5 caracteres")
    if not any(c.isdigit() for c in contrasena):
        motivos.append("Debe incluir al menos un número")
    if not any(c.isupper() for c in contrasena):
        motivos.append("Debe incluir al menos una mayúscula")
    return motivos


def estado(connection: sqlite3.Connection) -> dict:
    configurado = usuario_repository.existe_alguno(connection)
    registro_abierto = not configurado and codigo_registro_repository.existe_vigente(
        connection, _ahora().isoformat()
    )
    return {
        "api": API_VERSION,
        "configurado": configurado,
        "registro_abierto": registro_abierto,
        "sesion_activa": _sesion_activa_vigente(connection) is not None,
    }


def registrar(
    connection: sqlite3.Connection, codigo: str, usuario: str, contrasena: str, dispositivo: str | None
) -> dict:
    ahora = _ahora().isoformat()
    cerrado = AuthError("registro_cerrado", "El registro no está abierto")
    if usuario_repository.existe_alguno(connection):
        raise cerrado
    registro = codigo_registro_repository.obtener_por_hash(connection, hashlib.sha256(codigo.encode()).hexdigest())
    if registro is None:
        if not codigo_registro_repository.existe_vigente(connection, ahora):
            raise cerrado
        raise AuthError("codigo_invalido", "El código de registro no es válido")
    if registro.usado or registro.caduca_en <= ahora:
        raise AuthError("codigo_invalido", "El código de registro no es válido")
    motivos = motivos_contrasena_debil(contrasena)
    if motivos:
        raise AuthError("contrasena_debil", "La contraseña es demasiado débil", motivos=motivos)

    nuevo = usuario_repository.crear(connection, usuario, password_service.hashear(contrasena))
    codigo_registro_repository.marcar_usado(connection, registro.id)
    token = _abrir_sesion(connection, nuevo.id, dispositivo or DISPOSITIVO_POR_DEFECTO)
    return {"token": token, "usuario": nuevo.nombre_usuario}


def login(
    connection: sqlite3.Connection, usuario: str, contrasena: str, dispositivo: str, origen: str = "local"
) -> dict:
    limite_service.comprobar(connection, usuario)
    cuenta = usuario_repository.obtener_por_nombre(connection, usuario)
    if cuenta is None or not password_service.verificar(cuenta.hash_contrasena, contrasena):
        limite_service.registrar(connection, usuario, cuenta.id if cuenta else None, origen, exito=False)
        raise AuthError("credenciales_invalidas", "Usuario o contraseña incorrectos")
    limite_service.registrar(connection, usuario, cuenta.id, origen, exito=True)

    solicitud_login_repository.borrar_de_usuario(connection, cuenta.id)
    activa = _sesion_activa_vigente(connection)
    if activa is None:
        return {"token": _abrir_sesion(connection, cuenta.id, dispositivo), "usuario": cuenta.nombre_usuario}

    caduca_en = (_ahora() + CADUCIDAD_SOLICITUD).isoformat()
    solicitud = solicitud_login_repository.crear(
        connection, secrets.token_urlsafe(32), cuenta.id, dispositivo, caduca_en
    )
    return {
        "estado": "pendiente",
        "solicitud": solicitud.id,
        "sesion_activa_en": activa.dispositivo,
        "caduca_en_s": int(CADUCIDAD_SOLICITUD.total_seconds()),
    }


def consultar_solicitud(connection: sqlite3.Connection, solicitud_id: str) -> dict:
    solicitud = solicitud_login_repository.obtener(connection, solicitud_id)
    if solicitud is None:
        raise AuthError("solicitud_desconocida", "La solicitud no existe")
    estado_actual = solicitud.estado
    if estado_actual == "pendiente" and solicitud.caduca_en <= _ahora().isoformat():
        solicitud_login_repository.actualizar_estado(connection, solicitud.id, "caducada")
        estado_actual = "caducada"
    if estado_actual != "aprobada":
        return {"estado": estado_actual}

    cuenta = usuario_repository.obtener_por_id(connection, solicitud.usuario_id)
    token = _abrir_sesion(connection, cuenta.id, solicitud.dispositivo)
    solicitud_login_repository.borrar(connection, solicitud.id)
    return {"estado": "aprobada", "token": token, "usuario": cuenta.nombre_usuario}


def responder_solicitud(connection: sqlite3.Connection, solicitud_id: str, aprobar: bool) -> None:
    solicitud = solicitud_login_repository.obtener(connection, solicitud_id)
    if solicitud is None or solicitud.estado != "pendiente":
        return
    if not aprobar:
        solicitud_login_repository.actualizar_estado(connection, solicitud.id, "rechazada")
        return
    anterior = sesion_repository.obtener_activa(connection)
    if anterior is not None:
        sesion_repository.revocar(connection, anterior.id, "sustituida")
    solicitud_login_repository.actualizar_estado(connection, solicitud.id, "aprobada")


def autenticar(connection: sqlite3.Connection, token: str | None) -> Sesion:
    no_autenticado = AuthError("no_autenticado", "Hace falta iniciar sesión")
    if not token:
        raise no_autenticado
    sesion = sesion_repository.obtener_por_hash_token(connection, token_service.hashear(token))
    if sesion is None or token_service.esta_caducada(sesion.ultimo_acceso):
        raise no_autenticado
    if sesion.revocada:
        if sesion.motivo_revocacion == "desemparejado":
            raise AuthError("desemparejado", "El dispositivo fue desemparejado")
        raise no_autenticado
    sesion_repository.tocar_ultimo_acceso(connection, sesion.id)
    return sesion


def cerrar_sesion(connection: sqlite3.Connection, sesion: Sesion) -> None:
    sesion_repository.revocar(connection, sesion.id, "logout")


def desemparejar(connection: sqlite3.Connection, sesion: Sesion) -> None:
    sesion_repository.revocar(connection, sesion.id, "desemparejado")
