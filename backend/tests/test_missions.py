from fastapi.testclient import TestClient
from app.config import settings


def test_list_missions(client: TestClient):
    response = client.get(f"/api/v1/robots/{settings.DEFAULT_ROBOT_ID}/missions")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)


def test_create_mission_success(client: TestClient):
    payload = {
        "name": "Line 4 Component Drop",
        "pickup_station_id": "d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d01",
        "dropoff_station_id": "d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d02",
        "priority": 1,
        "idempotency_key": "test-key-12345",
    }
    response = client.post(
        f"/api/v1/robots/{settings.DEFAULT_ROBOT_ID}/missions",
        json=payload,
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Line 4 Component Drop"
    assert data["status"] == "in_progress"
    assert data["is_simulation"] is True


def test_idempotent_mission_submission(client: TestClient):
    payload = {
        "name": "Idempotent Order",
        "pickup_station_id": "d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d01",
        "dropoff_station_id": "d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d02",
        "priority": 2,
        "idempotency_key": "duplicate-key-xyz",
    }
    res1 = client.post(f"/api/v1/robots/{settings.DEFAULT_ROBOT_ID}/missions", json=payload)
    res2 = client.post(f"/api/v1/robots/{settings.DEFAULT_ROBOT_ID}/missions", json=payload)
    assert res1.status_code == 201
    assert res2.status_code == 201
    # Must return identical mission ID without creating duplicate
    assert res1.json()["id"] == res2.json()["id"]


def test_identical_stations_rejected(client: TestClient):
    payload = {
        "name": "Invalid Station Order",
        "pickup_station_id": "station-01",
        "dropoff_station_id": "station-01",
        "priority": 2,
    }
    res = client.post(f"/api/v1/robots/{settings.DEFAULT_ROBOT_ID}/missions", json=payload)
    assert res.status_code == 400
