"""Tokens de sesión opacos: generación, hash y caducidad por inactividad.

El token en claro solo lo tiene la app; el agente guarda su SHA-256. No hace falta Argon2
porque el token ya es aleatorio y largo (32 bytes), no una contraseña elegida por una persona.
"""

import hashlib
import secrets
from datetime import UTC, datetime, timedelta

INACTIVIDAD_MAXIMA = timedelta(days=30)
DURACION_SESION = timedelta(days=7)


def generar() -> str:
    """Devuelve un token nuevo de 32 bytes aleatorios en base64url (43 caracteres)."""
    return secrets.token_urlsafe(32)


def hashear(token: str) -> str:
    """Devuelve el SHA-256 del token en hexadecimal, que es lo que se guarda en la base de datos."""
    return hashlib.sha256(token.encode()).hexdigest()


def calcular_caducidad(creado_en: datetime) -> datetime:
    """Devuelve cuándo caduca una sesión creada en `creado_en`: 7 días después."""
    return creado_en + DURACION_SESION


def esta_caducada(ultimo_acceso: str) -> bool:
    """Indica si han pasado más de 30 días desde el último uso de la sesión."""
    return datetime.now(UTC) - datetime.fromisoformat(ultimo_acceso) > INACTIVIDAD_MAXIMA
