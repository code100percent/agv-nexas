import time
import jwt
from fastapi.testclient import TestClient
from app.api.v1.robots import FLEET_ROBOTS
from app.config import settings


TEST_JWT_SECRET_32B = "nexus-phase5-auth-secret-key-32b-secure!"


def _make_token(user_id: str, org_id: str, role: str) -> str:
    payload = {
        "sub": user_id,
        "exp": time.time() + 3600,
        "user_metadata": {
            "organization_id": org_id,
            "role": role,
        },
    }
    secret = settings.SUPABASE_JWT_SECRET or TEST_JWT_SECRET_32B
    return jwt.encode(payload, secret, algorithm="HS256")



def test_list_factory_stations(client: TestClient):
    token = _make_token(
        user_id="user-ops-01",
        org_id="a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        role="operator",
    )
    resp = client.get(
        "/api/v1/stations",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) >= 4

    names = [s["name"] for s in data]
    assert "Warehouse Bay A" in names
    assert "Assembly Line 4" in names
    assert "Charging Dock 01" in names
    assert "Quality Inspection 2" in names

    # Verify coordinate fields
    for s in data:
        assert "x" in s and "y" in s and "yaw" in s
        assert "station_type" in s


def test_list_robot_accessible_stations(client: TestClient):
    robot = FLEET_ROBOTS[0]
    token = _make_token(
        user_id="user-eng-01",
        org_id=robot.organization_id,
        role="engineer",
    )
    resp = client.get(
        f"/api/v1/robots/{robot.id}/stations",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) >= 1
    assert all(s["organization_id"] == robot.organization_id for s in data)


def test_stations_unauthorized_when_auth_required(client: TestClient):
    settings.REQUIRE_AUTH = True
    try:
        resp = client.get("/api/v1/stations")
        assert resp.status_code == 401
    finally:
        settings.REQUIRE_AUTH = False
