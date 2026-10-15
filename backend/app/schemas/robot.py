from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class RobotRecord(BaseModel):
    id: str
    organization_id: str
    name: str
    robot_code: str
    description: Optional[str] = None
    robot_type: str = "differential_drive"
    max_payload_kg: float = 15.0
    last_seen_at: Optional[datetime] = None


class RobotStatusResponse(BaseModel):
    robot_id: str
    connection_state: str  # connected, disconnected, reconnecting
    operating_mode: str    # idle, navigating, charging, error, paused
    data_freshness: str    # fresh, stale
    source: str            # ros2, simulated, disconnected
    last_heartbeat: datetime
    active_mission_id: Optional[str] = None
    has_faults: bool = False
    active_faults: List[str] = Field(default_factory=list)


class RobotConnectionResponse(BaseModel):
    robot_id: str
    connection_state: str
    source: str
    last_heartbeat: datetime
    gateway_uptime_seconds: float
    topics_subscribed: List[str] = Field(default_factory=list)
    ping_latency_ms: float = 1.2


class TeleopCommand(BaseModel):
    """Manual velocity command corresponding to geometry_msgs/Twist on /cmd_vel."""
    linear_velocity: float = Field(..., ge=-1.5, le=1.5, description="m/s linear speed")
    angular_velocity: float = Field(..., ge=-2.5, le=2.5, description="rad/s angular speed")
