from datetime import datetime, timezone
from typing import Any, Dict
from app.adapters.base import RobotAdapter
from app.schemas.map import MapOrigin, OccupancyGridMap
from app.schemas.telemetry import TelemetrySnapshot


class DisconnectedRobotAdapter(RobotAdapter):
    """Adapter explicitly simulating offline/disconnected robot state."""

    async def get_health(self) -> Dict[str, Any]:
        return {
            "status": "degraded",
            "mode": "disconnected",
            "message": "Robot is offline or connection severed",
        }

    async def get_connection_state(self, robot_id: str) -> str:
        return "disconnected"

    async def get_latest_telemetry(self, robot_id: str) -> TelemetrySnapshot:
        return TelemetrySnapshot(
            robot_id=robot_id,
            timestamp=datetime.now(timezone.utc),
            source="disconnected",
            connection_state="disconnected",
            data_freshness="stale",
            position_x=None,
            position_y=None,
            linear_velocity=None,
            angular_velocity=None,
            battery_percentage=None,
            robot_operating_state="offline",
            active_faults=["Hardware telemetry link disconnected"],
        )

    async def get_occupancy_grid(self, robot_id: str) -> OccupancyGridMap:
        return OccupancyGridMap(
            map_id="none",
            robot_id=robot_id,
            frame_id="map",
            width=2,
            height=2,
            resolution=0.05,
            origin=MapOrigin(x=0.0, y=0.0, yaw=0.0),
            timestamp=datetime.now(timezone.utc),
            encoding="int8_array",
            data=[-1, -1, -1, -1],
        )

    async def send_cmd_vel(
        self, robot_id: str, linear_velocity: float, angular_velocity: float
    ) -> bool:
        return False

    async def submit_mission(
        self, robot_id: str, mission_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        raise ConnectionError("Cannot dispatch mission: robot is disconnected")

    async def shutdown(self) -> None:
        pass
