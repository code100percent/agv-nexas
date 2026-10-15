import time
import jwt
from fastapi.testclient import TestClient
from app.config import settings

TEST_JWT_SECRET_32B = "nexus-phase5-auth-secret-key-32b-secure!"


def test_auth_rejection_when_required(client: TestClient):
    settings.REQUIRE_AUTH = True
    try:
        response = client.get("/api/v1/robots")
        assert response.status_code == 401
    finally:
        settings.REQUIRE_AUTH = False


def test_invalid_token_format(client: TestClient):
    settings.REQUIRE_AUTH = True
    try:
        response = client.get("/api/v1/robots", headers={"Authorization": "NotBearer token"})
        assert response.status_code == 401
    finally:
        settings.REQUIRE_AUTH = False


def test_expired_token_rejection(client: TestClient):
    settings.REQUIRE_AUTH = True
    try:
        # Create expired token
        expired_payload = {
            "sub": "user-expired",
            "exp": time.time() - 3600,
            "role": "operator",
        }
        token = jwt.encode(expired_payload, TEST_JWT_SECRET_32B, algorithm="HS256")
        response = client.get("/api/v1/robots", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 401
    finally:
        settings.REQUIRE_AUTH = False


def test_tenant_isolation(client: TestClient):
    # A user from a different organization cannot access Titan-01
    settings.REQUIRE_AUTH = True
    try:
        foreign_org_payload = {
            "sub": "foreign-operator",
            "exp": time.time() + 3600,
            "user_metadata": {
                "organization_id": "00000000-0000-0000-0000-000000000000",
                "role": "operator",
            },
        }
        token = jwt.encode(foreign_org_payload, TEST_JWT_SECRET_32B, algorithm="HS256")
        response = client.get(
            f"/api/v1/robots/{settings.DEFAULT_ROBOT_ID}/status",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 403
    finally:
        settings.REQUIRE_AUTH = False

