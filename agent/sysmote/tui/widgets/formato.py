"""Textos y formatos de fecha que comparten las pestañas de la TUI."""

from datetime import datetime

ETIQUETAS_SERVIDORES = {"https": "HTTPS (USB/LAN)", "interno": "HTTP interno", "iroh": "iroh"}


def fecha_local(iso: str) -> str:
    """Convierte una fecha ISO 8601 (guardada en UTC) a `dd/mm/aaaa hh:mm:ss` en la hora local."""
    return datetime.fromisoformat(iso).astimezone().strftime("%d/%m/%Y %H:%M:%S")


def hora_local(iso: str) -> str:
    """Convierte una fecha ISO 8601 (guardada en UTC) a `hh:mm:ss` en la hora local."""
    return datetime.fromisoformat(iso).astimezone().strftime("%H:%M:%S")
