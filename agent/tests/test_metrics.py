"""Comprueba el endpoint GET /metrics con datos reales de la máquina."""

from fastapi.testclient import TestClient

from companion.main import app

client = TestClient(app)


def test_get_metrics_returns_real_data():
    response = client.get("/metrics")
    assert response.status_code == 200

    body = response.json()
    assert 0.0 <= body["cpu_percent"] <= 100.0
    assert body["cpu_temp_c"] is None or body["cpu_temp_c"] > 0
    assert body["ram_used_gb"] > 0
    assert body["ram_total_gb"] >= body["ram_used_gb"]
    assert isinstance(body["partitions"], list)
    assert len(body["partitions"]) >= 1

    partition = body["partitions"][0]
    assert partition["device"].startswith("/dev/")
    assert partition["total_gb"] >= partition["used_gb"] >= 0
