from fastapi.testclient import TestClient


def test_liveness_endpoint(client: TestClient):
    response = client.get("/health/live")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "alive"
    assert "timestamp" in data
    assert "X-Request-ID" in response.headers


def test_readiness_endpoint(client: TestClient):
    response = client.get("/health/ready")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ready"
    assert data["adapter_mode"] in ("simulated", "ros2", "disconnected")
    assert "adapter_health" in data
