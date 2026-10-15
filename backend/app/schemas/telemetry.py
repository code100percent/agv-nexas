from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field, field_validator
import math


class TelemetrySnapshot(BaseModel):
    """Normalized, typed telemetry snapshot from ROS 2 or simulator."""

    robot_id: str
    timestamp: datetime
    source: str = Field(
        ...,
        description="'ros2', 'simulated', or 'disconnected'",
    )
    connection_state: str = Field(
        ...,
        description="'connected', 'disconnected', 'reconnecting'",
    )
    data_freshness: str = Field(
        ...,
        description="'fresh' or 'stale'",
    )

    # Kinematics and Dead Reckoning
    position_x: Optional[float] = None
    position_y: Optional[float] = None
    position_z: Optional[float] = 0.0
    yaw: Optional[float] = None
    linear_velocity: Optional[float] = None
    angular_velocity: Optional[float] = None

    # Hardware & Encoder State (Differential Drive)
    left_wheel_ticks: Optional[int] = None
    right_wheel_ticks: Optional[int] = None
    battery_percentage: Optional[float] = None
    battery_voltage: Optional[float] = None
    is_charging: Optional[bool] = False

    # High-level state
    robot_operating_state: Optional[str] = "idle"
    localization_confidence: Optional[float] = 1.0
    active_mission_id: Optional[str] = None
    active_faults: List[str] = Field(default_factory=list)

    @field_validator(
        "position_x",
        "position_y",
        "position_z",
        "yaw",
        "linear_velocity",
        "angular_velocity",
        "battery_percentage",
        "battery_voltage",
    )
    @classmethod
    def check_finite(cls, v: Optional[float]) -> Optional[float]:
        if v is not None and (math.isnan(v) or math.isinf(v)):
            return None
        return v

    @field_validator("battery_percentage")
    @classmethod
    def check_battery_range(cls, v: Optional[float]) -> Optional[float]:
        if v is not None:
            return max(0.0, min(100.0, v))
        return v
