import time
import jwt
import pytest
from fastapi.testclient import TestClient
from app.adapters import get_robot_adapter, reset_robot_adapter
from app.config import settings
from app.core.logging import redact_sensitive_text

TEST_JWT_SECRET_32B = "nexus-phase5-failure-test-secret-32b!"


def _make_token(user_id: str, org_id: str, role: str) -> str:
    payload = {
        "sub": user_id,
        "exp": time.time() + 3600,
        "user_metadata": {
            "organization_id": org_id,
            "role": role,
        },
    }
    return jwt.encode(payload, TEST_JWT_SECRET_32B, algorithm="HS256")


def test_sensitive_log_redaction():
    """Verify that sensitive tokens, JWTs, and passwords are unconditionally redacted."""
    raw_bearer = "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_token_content"
    redacted_bearer = redact_sensitive_text(raw_bearer)
    assert "dummy_token_content" not in redacted_bearer
    assert "[REDACTED_TOKEN]" in redacted_bearer

    raw_json_pwd = '{"user": "admin", "password": "SuperSecretPassword123!", "service_role_key": "secret_key_abc"}'
    redacted_json = redact_sensitive_text(raw_json_pwd)
    assert "SuperSecretPassword123!" not in redacted_json
    assert "secret_key_abc" not in redacted_json
    assert '"password": "[REDACTED]"' in redacted_json


def test_payload_size_limit_rejection(client: TestClient):
    """Verify that requests exceeding MAX_REQUEST_BODY_BYTES return HTTP 413."""
    headers = {
        "Content-Length": str(3 * 1024 * 1024),  # 3 MB > 2 MB limit
        "Content-Type": "application/json",
    }
    response = client.post(
        f"/api/v1/robots/{settings.DEFAULT_ROBOT_ID}/missions",
        content=b"x",
        headers=headers,
    )
    assert response.status_code == 413
    assert "exceeds maximum allowed size" in response.json()["detail"]


def test_viewer_role_cannot_dispatch_mission(client: TestClient):
    """Verify that a user with 'viewer' role is forbidden from dispatching autonomous missions."""
    settings.REQUIRE_AUTH = True
    try:
        viewer_token = _make_token(
            user_id="user-viewer-01",
            org_id=settings.DEFAULT_ORG_ID,
            role="viewer",
        )
        payload = {
            "name": "Unauthorized Transfer",
            "pickup_station_id": "d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d01",
            "dropoff_station_id": "d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d02",
            "priority": 2,
        }
        response = client.post(
            f"/api/v1/robots/{settings.DEFAULT_ROBOT_ID}/missions",
            json=payload,
            headers={"Authorization": f"Bearer {viewer_token}"},
        )
        assert response.status_code == 403
        assert "not authorized to dispatch autonomous missions" in response.json()["detail"]
    finally:
        settings.REQUIRE_AUTH = False


def test_viewer_role_cannot_issue_teleop_commands(client: TestClient):
    """Verify that read-only viewers cannot send velocity commands to AGVs."""
    settings.REQUIRE_AUTH = True
    try:
        viewer_token = _make_token(
            user_id="user-viewer-02",
            org_id=settings.DEFAULT_ORG_ID,
            role="viewer",
        )
        teleop_payload = {
            "linear_velocity": 0.5,
            "angular_velocity": 0.0,
            "duration_seconds": 1.0,
        }
        response = client.post(
            f"/api/v1/robots/{settings.DEFAULT_ROBOT_ID}/teleop",
            json=teleop_payload,
            headers={"Authorization": f"Bearer {viewer_token}"},
        )
        assert response.status_code == 403
    finally:
        settings.REQUIRE_AUTH = False


def test_disconnected_adapter_handling(client: TestClient):
    """Verify system behavior when robot adapter is switched to 'disconnected' mode."""
    original_mode = settings.ROBOT_ADAPTER_MODE
    try:
        settings.ROBOT_ADAPTER_MODE = "disconnected"
        reset_robot_adapter()
        adapter = get_robot_adapter()

        # Adapter health indicates degraded/disconnected
        health = pytest.importorskip("asyncio").run(adapter.get_health())
        assert health["status"] in ("degraded", "disconnected")

        # Readiness endpoint reflects disconnected adapter
        ready_resp = client.get("/health/ready")

        assert ready_resp.status_code == 503
        assert ready_resp.json()["status"] == "not_ready"
    finally:
        settings.ROBOT_ADAPTER_MODE = original_mode
        reset_robot_adapter()


def test_mission_duplicate_idempotency_key(client: TestClient):
    """Verify duplicate mission submissions with identical idempotency keys are cleanly suppressed."""
    idempotency_key = f"test-idem-key-{time.time()}"
    payload = {
        "name": "Idempotent Material Flow",
        "pickup_station_id": "d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d01",
        "dropoff_station_id": "d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d02",
        "priority": 1,
        "idempotency_key": idempotency_key,
    }

    # First dispatch
    resp1 = client.post(
        f"/api/v1/robots/{settings.DEFAULT_ROBOT_ID}/missions",
        json=payload,
    )
    assert resp1.status_code == 201
    mission1_id = resp1.json()["id"]

    # Second dispatch with identical idempotency key
    resp2 = client.post(
        f"/api/v1/robots/{settings.DEFAULT_ROBOT_ID}/missions",
        json=payload,
    )
    assert resp2.status_code == 201
    mission2_id = resp2.json()["id"]

    # Must return existing mission without generating new record
    assert mission1_id == mission2_id
