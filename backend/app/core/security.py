import time
from typing import Any, Dict, Optional
import jwt
from fastapi import Header, HTTPException, Query, status
from pydantic import BaseModel
from app.config import settings
from app.core.logging import get_logger

logger = get_logger("security")


class AuthenticatedUser(BaseModel):
    user_id: str
    email: Optional[str] = None
    role: str = "operator"
    organization_id: str = settings.DEFAULT_ORG_ID
    is_authenticated: bool = True


def decode_supabase_jwt(token: str) -> Dict[str, Any]:
    """Decode and validate a Supabase Auth JWT token."""
    try:
        # If a secret is provided, verify signature
        if settings.SUPABASE_JWT_SECRET:
            payload = jwt.decode(
                token,
                settings.SUPABASE_JWT_SECRET,
                algorithms=["HS256"],
                options={"verify_aud": False},
            )
        else:
            # Without local secret, verify unverified claims structure & expiration
            payload = jwt.decode(
                token,
                options={"verify_signature": False, "verify_exp": True},
            )

        # Check expiration claim
        exp = payload.get("exp")
        if exp and exp < time.time():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has expired",
            )

        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token signature has expired",
        )
    except jwt.InvalidTokenError as e:
        logger.warning(f"Invalid token encountered: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
        )


def get_current_user(
    authorization: Optional[str] = Header(None),
) -> AuthenticatedUser:
    """Dependency for authenticating REST requests via Bearer token."""
    if not authorization:
        if not settings.REQUIRE_AUTH:
            # Development fallback operator persona
            return AuthenticatedUser(
                user_id="dev-operator-01",
                email="operator@nexus.factory",
                role="operator",
                organization_id=settings.DEFAULT_ORG_ID,
            )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
            headers={"WWW-Authenticate": "Bearer"},
        )

    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Authorization header format. Expected 'Bearer <token>'",
        )

    token = parts[1]

    # Special handling for simulated development tokens
    if not settings.REQUIRE_AUTH and token.startswith("mock-dev-token"):
        return AuthenticatedUser(
            user_id="dev-operator-01",
            email="operator@nexus.factory",
            role="operator",
            organization_id=settings.DEFAULT_ORG_ID,
        )

    payload = decode_supabase_jwt(token)
    user_id = payload.get("sub") or payload.get("id")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token subject (sub) missing",
        )

    user_meta = payload.get("user_metadata", {})
    org_id = user_meta.get("organization_id", settings.DEFAULT_ORG_ID)
    role = user_meta.get("role", payload.get("role", "operator"))

    return AuthenticatedUser(
        user_id=str(user_id),
        email=payload.get("email"),
        role=role,
        organization_id=org_id,
    )


def verify_ws_token(token: Optional[str]) -> AuthenticatedUser:
    """Validate WebSocket authentication token passed via query param or initial message."""
    if not token:
        if not settings.REQUIRE_AUTH:
            return AuthenticatedUser(
                user_id="dev-operator-ws",
                email="operator@nexus.factory",
                role="operator",
                organization_id=settings.DEFAULT_ORG_ID,
            )
        raise ValueError("Missing authentication token for WebSocket connection")

    if not settings.REQUIRE_AUTH and token.startswith("mock-dev-token"):
        return AuthenticatedUser(
            user_id="dev-operator-ws",
            email="operator@nexus.factory",
            role="operator",
            organization_id=settings.DEFAULT_ORG_ID,
        )

    payload = decode_supabase_jwt(token)
    user_id = payload.get("sub") or payload.get("id")
    if not user_id:
        raise ValueError("Invalid token subject for WebSocket")

    user_meta = payload.get("user_metadata", {})
    return AuthenticatedUser(
        user_id=str(user_id),
        email=payload.get("email"),
        role=user_meta.get("role", "operator"),
        organization_id=user_meta.get("organization_id", settings.DEFAULT_ORG_ID),
    )


def check_robot_authorization(user: AuthenticatedUser, robot_org_id: str) -> None:
    """Tenant check: user must belong to the organization owning the robot."""
    if user.organization_id != robot_org_id and user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden: robot belongs to another organization",
        )
