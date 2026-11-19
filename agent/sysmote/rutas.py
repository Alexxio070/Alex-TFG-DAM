"""Rutas de todos los archivos que el agente guarda en el equipo del usuario.

Los datos van en `~/.local/share/sysmote/` y la configuración en `~/.config/sysmote/`,
siempre con permisos solo para el usuario (carpetas 0700, archivos 0600). Los módulos
leen estas constantes al usarlas, no al importarse, para que los tests puedan
redirigirlas a una carpeta temporal.
"""

from pathlib import Path

_DATOS = Path.home() / ".local" / "share" / "sysmote"
_CONFIG = Path.home() / ".config" / "sysmote"

DB_PATH = _DATOS / "sysmote.db"
IROH_KEY_PATH = _DATOS / "iroh_secret_key.bin"
CONFIG_PATH = _CONFIG / "config.toml"
CERT_PATH = _CONFIG / "cert.pem"
KEY_PATH = _CONFIG / "key.pem"
