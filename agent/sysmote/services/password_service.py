"""Hash y verificación de contraseñas con Argon2 (librería `argon2-cffi`)."""

from functools import cache

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError

_hasher = PasswordHasher()


def hashear(contrasena: str) -> str:
    """Devuelve el hash Argon2 de la contraseña, con sal aleatoria; es lo único que se guarda."""
    return _hasher.hash(contrasena)


def verificar(hash_contrasena: str, contrasena: str) -> bool:
    """Indica si la contraseña corresponde al hash; un hash dañado cuenta como incorrecta."""
    try:
        return _hasher.verify(hash_contrasena, contrasena)
    except (VerificationError, InvalidHashError):
        return False


@cache
def _hash_de_relleno() -> str:
    return _hasher.hash("relleno")


def verificar_con_relleno(contrasena: str) -> None:
    """Gasta el mismo tiempo que `verificar` sobre un hash que no es de nadie.

    Se usa cuando el usuario no existe, para que la respuesta no sea más rápida que la de una
    contraseña incorrecta y no delate si el nombre de usuario existe.
    """
    verificar(_hash_de_relleno(), contrasena)
