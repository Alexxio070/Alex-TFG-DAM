import pytest

from sysmote import database
from sysmote.services import config_service, tls_service


@pytest.fixture(autouse=True)
def entorno_aislado(tmp_path, monkeypatch):
    """Ningún test toca la configuración, el certificado ni la base de datos reales."""
    monkeypatch.setattr(config_service, "CONFIG_PATH", tmp_path / "config.toml")
    monkeypatch.setattr(database, "DB_PATH", tmp_path / "datos" / "sysmote.db")
    monkeypatch.setattr(tls_service, "CONFIG_DIR", tmp_path / "tls")
    monkeypatch.setattr(tls_service, "CERT_PATH", tmp_path / "tls" / "cert.pem")
    monkeypatch.setattr(tls_service, "KEY_PATH", tmp_path / "tls" / "key.pem")
