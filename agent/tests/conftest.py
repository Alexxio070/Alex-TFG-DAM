import pytest

from sysmote import rutas


@pytest.fixture(autouse=True)
def entorno_aislado(tmp_path, monkeypatch):
    """Ningún test toca la configuración, el certificado, la clave iroh ni la base de datos reales."""
    monkeypatch.setattr(rutas, "CONFIG_PATH", tmp_path / "config.toml")
    monkeypatch.setattr(rutas, "DB_PATH", tmp_path / "datos" / "sysmote.db")
    monkeypatch.setattr(rutas, "CERT_PATH", tmp_path / "tls" / "cert.pem")
    monkeypatch.setattr(rutas, "KEY_PATH", tmp_path / "tls" / "key.pem")
    monkeypatch.setattr(rutas, "IROH_KEY_PATH", tmp_path / "iroh" / "iroh_secret_key.bin")
