"""Configuración editable a mano del agente, en `~/.config/sysmote/config.toml`.

De momento solo la duración del bloqueo por intentos fallidos:

    [seguridad]
    bloqueo_minutos = 2
"""

import tomllib
from datetime import timedelta

from sysmote import rutas

BLOQUEO_POR_DEFECTO_MINUTOS = 10


def duracion_bloqueo() -> timedelta:
    """Devuelve cuánto dura el bloqueo; 10 minutos si no hay archivo o no tiene la clave."""
    if not rutas.CONFIG_PATH.exists():
        return timedelta(minutes=BLOQUEO_POR_DEFECTO_MINUTOS)
    seguridad = tomllib.loads(rutas.CONFIG_PATH.read_text()).get("seguridad", {})
    return timedelta(minutes=seguridad.get("bloqueo_minutos", BLOQUEO_POR_DEFECTO_MINUTOS))
