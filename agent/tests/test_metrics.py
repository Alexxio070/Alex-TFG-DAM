"""Comprueba el endpoint GET /metrics con datos reales de la máquina."""

import pytest
from fastapi.testclient import TestClient

from sysmote.api.deps import requiere_sesion
from sysmote.main import app

client = TestClient(app)


@pytest.fixture(autouse=True)
def sin_login():
    app.dependency_overrides[requiere_sesion] = lambda: None
    yield
    app.dependency_overrides.clear()


def test_get_metrics_returns_real_data():
    response = client.get("/metrics")
    assert response.status_code == 200

    body = response.json()
    assert 0.0 <= body["cpu_percent"] <= 100.0
    assert body["cpu_temp_c"] is None or body["cpu_temp_c"] > 0
    assert body["ram_used_gb"] > 0
    assert body["ram_total_gb"] >= body["ram_used_gb"]
    assert isinstance(body["partitions"], list)
    for partition in body["partitions"]:
        assert partition["device"].startswith("/dev/")
        assert partition["total_gb"] >= partition["used_gb"] >= 0
