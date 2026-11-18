from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError

_hasher = PasswordHasher()


def hashear(contrasena: str) -> str:
    return _hasher.hash(contrasena)


def verificar(hash_contrasena: str, contrasena: str) -> bool:
    try:
        return _hasher.verify(hash_contrasena, contrasena)
    except (VerificationError, InvalidHashError):
        return False
