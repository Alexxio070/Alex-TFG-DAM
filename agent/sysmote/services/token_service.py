import hashlib
import secrets
from datetime import UTC, datetime, timedelta

INACTIVIDAD_MAXIMA = timedelta(days=30)


def generar() -> str:
    return secrets.token_urlsafe(32)


def hashear(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def esta_caducada(ultimo_acceso: str) -> bool:
    return datetime.now(UTC) - datetime.fromisoformat(ultimo_acceso) > INACTIVIDAD_MAXIMA
