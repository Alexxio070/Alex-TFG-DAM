import tomllib
from datetime import timedelta
from pathlib import Path

CONFIG_PATH = Path.home() / ".config" / "sysmote" / "config.toml"
BLOQUEO_POR_DEFECTO_MINUTOS = 10


def duracion_bloqueo() -> timedelta:
    if not CONFIG_PATH.exists():
        return timedelta(minutes=BLOQUEO_POR_DEFECTO_MINUTOS)
    seguridad = tomllib.loads(CONFIG_PATH.read_text()).get("seguridad", {})
    return timedelta(minutes=seguridad.get("bloqueo_minutos", BLOQUEO_POR_DEFECTO_MINUTOS))
