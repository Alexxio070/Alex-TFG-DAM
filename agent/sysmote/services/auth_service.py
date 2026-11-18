import hashlib
import secrets
import sqlite3
from datetime import UTC, datetime, timedelta

from sysmote.models.auth import Sesion, SolicitudLogin
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
CADUCIDAD_CODIGO = timedelta(minutes=10)
ALFABETO_CODIGO = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"


def _ahora() -> datetime:
    return datetime.now(UTC)


def hash_codigo(codigo: str) -> str:
    # El alfabeto base32 no tiene 0 ni 1: al teclear a mano se leen como O e I.
    normalizado = codigo.replace("-", "").replace(" ", "").upper().replace("0", "O").replace("1", "I")
    return hashlib.sha256(normalizado.encode()).hexdigest()


def sesion_activa(connection: sqlite3.Connection) -> Sesion | None:
    sesion = sesion_repository.obtener_activa(connection)
    if sesion is None or token_service.esta_caducada(sesion.ultimo_acceso):
        return None
    return sesion


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
        "sesion_activa": sesion_activa(connection) is not None,
    }


def registrar(
    connection: sqlite3.Connection, codigo: str, usuario: str, contrasena: str, dispositivo: str
) -> dict:
    ahora = _ahora().isoformat()
    cerrado = AuthError("registro_cerrado", "El registro no está abierto")
    invalido = AuthError("codigo_invalido", "El código de registro no es válido")
    if usuario_repository.existe_alguno(connection):
        raise cerrado
    registro = codigo_registro_repository.obtener_por_hash(connection, hash_codigo(codigo))
    if registro is None:
        raise invalido if codigo_registro_repository.existe_alguno(connection) else cerrado
    if registro.usado:
        raise invalido
    if registro.caduca_en <= ahora:
        raise AuthError("codigo_caducado", "El código de registro ha caducado")
    motivos = motivos_contrasena_debil(contrasena)
    if motivos:
        raise AuthError("contrasena_debil", "La contraseña es demasiado débil", motivos=motivos)

    nuevo = usuario_repository.crear(connection, usuario, password_service.hashear(contrasena))
    codigo_registro_repository.marcar_usado(connection, registro.id)
    token = _abrir_sesion(connection, nuevo.id, dispositivo)
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
    activa = sesion_activa(connection)
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


def datos_sesion(connection: sqlite3.Connection, sesion: Sesion) -> dict:
    cuenta = usuario_repository.obtener_por_id(connection, sesion.usuario_id)
    return {"usuario": cuenta.nombre_usuario, "dispositivo": sesion.dispositivo, "creada": sesion.creado_en}


def cerrar_sesion(connection: sqlite3.Connection, sesion: Sesion) -> None:
    sesion_repository.revocar(connection, sesion.id, "logout")


def desemparejar(connection: sqlite3.Connection, sesion: Sesion) -> None:
    sesion_repository.revocar(connection, sesion.id, "desemparejado")


def desemparejar_sesion_activa(connection: sqlite3.Connection) -> None:
    activa = sesion_activa(connection)
    if activa is not None:
        desemparejar(connection, activa)


def abrir_registro(connection: sqlite3.Connection) -> tuple[str, str]:
    if usuario_repository.existe_alguno(connection):
        raise AuthError("ya_configurado", "Ya existe una cuenta")
    caracteres = "".join(secrets.choice(ALFABETO_CODIGO) for _ in range(16))
    codigo = "-".join(caracteres[i : i + 4] for i in range(0, 16, 4))
    caduca_en = (_ahora() + CADUCIDAD_CODIGO).isoformat()
    codigo_registro_repository.borrar_todos(connection)
    codigo_registro_repository.crear(connection, hash_codigo(codigo), caduca_en)
    return codigo, caduca_en


def cambiar_contrasena(connection: sqlite3.Connection, nueva: str) -> None:
    motivos = motivos_contrasena_debil(nueva)
    if motivos:
        raise AuthError("contrasena_debil", "La contraseña es demasiado débil", motivos=motivos)
    cuenta = usuario_repository.obtener_primero(connection)
    usuario_repository.actualizar_contrasena(connection, cuenta.id, password_service.hashear(nueva))
    sesion_repository.revocar_todas_de_usuario(connection, cuenta.id, "contrasena_cambiada")


def cerrar_todas_las_sesiones(connection: sqlite3.Connection) -> None:
    cuenta = usuario_repository.obtener_primero(connection)
    sesion_repository.revocar_todas_de_usuario(connection, cuenta.id, "cerrar_todas")


def reiniciar_intentos(connection: sqlite3.Connection) -> None:
    cuenta = usuario_repository.obtener_primero(connection)
    limite_service.reiniciar(connection, cuenta.nombre_usuario)


def solicitud_pendiente(connection: sqlite3.Connection) -> SolicitudLogin | None:
    solicitud = solicitud_login_repository.obtener_pendiente(connection)
    if solicitud is not None and solicitud.caduca_en <= _ahora().isoformat():
        solicitud_login_repository.actualizar_estado(connection, solicitud.id, "caducada")
        return None
    return solicitud
