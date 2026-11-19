"""Certificado TLS: permisos, que no se regenere y que la huella sea la del certificado."""

import hashlib
import stat

from cryptography import x509
from cryptography.hazmat.primitives import serialization

from sysmote.services import tls_service


def test_crea_certificado_y_clave_con_permisos_seguros():
    cert_path, key_path = tls_service.asegurar_certificado()

    assert stat.S_IMODE(key_path.stat().st_mode) == 0o600
    assert stat.S_IMODE(cert_path.stat().st_mode) == 0o600
    assert stat.S_IMODE(cert_path.parent.stat().st_mode) == 0o700


def test_no_regenera_si_ya_existen():
    cert_path, key_path = tls_service.asegurar_certificado()
    cert, key = cert_path.read_bytes(), key_path.read_bytes()

    tls_service.asegurar_certificado()

    assert cert_path.read_bytes() == cert
    assert key_path.read_bytes() == key


def test_huella_coincide_con_el_sha256_del_der_del_certificado():
    cert_path, _ = tls_service.asegurar_certificado()
    der = x509.load_pem_x509_certificate(cert_path.read_bytes()).public_bytes(
        serialization.Encoding.DER
    )
    assert tls_service.huella_sha256() == hashlib.sha256(der).hexdigest()
