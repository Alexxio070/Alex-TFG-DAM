import pytest

from sysmote.services import config_service


@pytest.fixture(autouse=True)
def config_aislada(tmp_path, monkeypatch):
    monkeypatch.setattr(config_service, "CONFIG_PATH", tmp_path / "config.toml")
