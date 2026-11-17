import hashlib
import re
import stat

import pytest
from cryptography import x509
from cryptography.hazmat.primitives import serialization

from sysmote.services import tls_service


@pytest.fixture(autouse=True)
def rutas_temporales(tmp_path, monkeypatch):
    config = tmp_path / "config"
    monkeypatch.setattr(tls_service, "CONFIG_DIR", config)
    monkeypatch.setattr(tls_service, "CERT_PATH", config / "cert.pem")
    monkeypatch.setattr(tls_service, "KEY_PATH", config / "key.pem")


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


def test_huella_es_sha256_hexadecimal_de_64_caracteres():
    tls_service.asegurar_certificado()
    assert re.fullmatch(r"[0-9a-f]{64}", tls_service.huella_sha256())


def test_huella_coincide_con_el_sha256_del_der_del_certificado():
    cert_path, _ = tls_service.asegurar_certificado()
    der = x509.load_pem_x509_certificate(cert_path.read_bytes()).public_bytes(serialization.Encoding.DER)
    assert tls_service.huella_sha256() == hashlib.sha256(der).hexdigest()


def test_certificado_y_clave_son_un_par_valido():
    cert_path, key_path = tls_service.asegurar_certificado()
    certificado = x509.load_pem_x509_certificate(cert_path.read_bytes())
    clave = serialization.load_pem_private_key(key_path.read_bytes(), password=None)

    publica = lambda k: k.public_bytes(serialization.Encoding.DER, serialization.PublicFormat.SubjectPublicKeyInfo)
    assert publica(certificado.public_key()) == publica(clave.public_key())
