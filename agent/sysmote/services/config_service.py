import tomllib
from datetime import timedelta

from sysmote import rutas

BLOQUEO_POR_DEFECTO_MINUTOS = 10


def duracion_bloqueo() -> timedelta:
    if not rutas.CONFIG_PATH.exists():
        return timedelta(minutes=BLOQUEO_POR_DEFECTO_MINUTOS)
    seguridad = tomllib.loads(rutas.CONFIG_PATH.read_text()).get("seguridad", {})
    return timedelta(minutes=seguridad.get("bloqueo_minutos", BLOQUEO_POR_DEFECTO_MINUTOS))
