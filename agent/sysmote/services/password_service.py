"""Hash y verificación de contraseñas con Argon2 (librería `argon2-cffi`)."""

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
