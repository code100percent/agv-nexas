from fastapi.testclient import TestClient
from app.config import settings


def test_list_robots(client: TestClient):
    response = client.get("/api/v1/robots")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1
    assert any(r["id"] == settings.DEFAULT_ROBOT_ID for r in data)


def test_get_robot_status(client: TestClient):
    response = client.get(f"/api/v1/robots/{settings.DEFAULT_ROBOT_ID}/status")
    assert response.status_code == 200
    data = response.json()
    assert data["robot_id"] == settings.DEFAULT_ROBOT_ID
    assert data["connection_state"] == "connected"
    assert data["data_freshness"] == "fresh"
    assert data["source"] == "simulated"


def test_get_robot_status_not_found(client: TestClient):
    response = client.get("/api/v1/robots/non-existent-robot-id/status")
    assert response.status_code == 404


def test_get_robot_telemetry(client: TestClient):
    response = client.get(f"/api/v1/robots/{settings.DEFAULT_ROBOT_ID}/telemetry")
    assert response.status_code == 200
    data = response.json()
    assert data["robot_id"] == settings.DEFAULT_ROBOT_ID
    assert "position_x" in data
    assert "position_y" in data
    assert "yaw" in data
    assert "battery_percentage" in data
    assert data["source"] == "simulated"


def test_get_robot_connection(client: TestClient):
    response = client.get(f"/api/v1/robots/{settings.DEFAULT_ROBOT_ID}/connection")
    assert response.status_code == 200
    data = response.json()
    assert data["robot_id"] == settings.DEFAULT_ROBOT_ID
    assert data["connection_state"] == "connected"
    assert "/odom" in data["topics_subscribed"]


def test_send_teleop_command(client: TestClient):
    response = client.post(
        f"/api/v1/robots/{settings.DEFAULT_ROBOT_ID}/teleop",
        json={"linear_velocity": 0.5, "angular_velocity": 0.2},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "command_sent"
    assert data["linear_velocity"] == 0.5
    assert data["angular_velocity"] == 0.2
