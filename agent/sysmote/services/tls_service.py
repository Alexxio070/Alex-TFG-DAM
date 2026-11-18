"""Certificado TLS autofirmado del agente y su huella, para el HTTPS de USB y red local.

La app guarda la huella al emparejar y solo confía en ese certificado (certificate pinning).
"""

import hashlib
import os
from datetime import UTC, datetime, timedelta
from pathlib import Path

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.x509.oid import NameOID

from sysmote import rutas

_VALIDEZ = timedelta(days=3650)


def _escribir_privado(path: Path, contenido: bytes) -> None:
    # Con 0600 desde la creación, para que la clave nunca sea legible por otros usuarios.
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "wb") as archivo:
        archivo.write(contenido)


def _generar() -> tuple[bytes, bytes]:
    clave = ec.generate_private_key(ec.SECP256R1())
    nombre = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "sysmote")])
    ahora = datetime.now(UTC)
    certificado = (
        x509.CertificateBuilder()
        .subject_name(nombre)
        .issuer_name(nombre)
        .public_key(clave.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(ahora)
        .not_valid_after(ahora + _VALIDEZ)
        .sign(clave, hashes.SHA256())
    )
    cert_pem = certificado.public_bytes(serialization.Encoding.PEM)
    key_pem = clave.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    )
    return cert_pem, key_pem


def asegurar_certificado() -> tuple[Path, Path]:
    """Genera el certificado y su clave (EC P-256, 10 años) si no existen, y devuelve sus rutas.

    Si ya existen no los toca: regenerarlos cambiaría la huella y la app rechazaría la conexión.
    """
    carpeta = rutas.CERT_PATH.parent
    carpeta.mkdir(mode=0o700, parents=True, exist_ok=True)
    os.chmod(carpeta, 0o700)
    if not certificado_existe():
        cert_pem, key_pem = _generar()
        rutas.CERT_PATH.unlink(missing_ok=True)
        rutas.KEY_PATH.unlink(missing_ok=True)
        _escribir_privado(rutas.KEY_PATH, key_pem)
        _escribir_privado(rutas.CERT_PATH, cert_pem)
    return rutas.CERT_PATH, rutas.KEY_PATH


def certificado_existe() -> bool:
    """Indica si ya existen el certificado y su clave."""
    return rutas.CERT_PATH.exists() and rutas.KEY_PATH.exists()


def huella_sha256() -> str:
    """Devuelve la huella del certificado: SHA-256 del DER en hexadecimal minúscula (64 caracteres)."""
    certificado = x509.load_pem_x509_certificate(rutas.CERT_PATH.read_bytes())
    return hashlib.sha256(certificado.public_bytes(serialization.Encoding.DER)).hexdigest()
