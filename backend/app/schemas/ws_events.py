from datetime import datetime, timezone
from typing import Any, Dict
from pydantic import BaseModel, Field


class WebSocketEventEnvelope(BaseModel):
    """Standardized event envelope for real-time telemetry streaming."""

    schema_version: int = 1
    event: str = Field(
        ...,
        description="Event name, e.g. 'robot.telemetry', 'robot.pose', 'robot.map', 'robot.status', 'robot.connection', 'heartbeat'",
    )
    robot_id: str
    timestamp: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc)
    )
    source: str = Field(
        ...,
        description="'ros2', 'simulated', or 'disconnected'",
    )
    payload: Dict[str, Any]
