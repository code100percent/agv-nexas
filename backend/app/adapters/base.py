from abc import ABC, abstractmethod
from typing import Any, Dict
from app.schemas.map import OccupancyGridMap
from app.schemas.telemetry import TelemetrySnapshot


class RobotAdapter(ABC):
    """Abstract interface defining the contract between backend services and robot hardware/simulation."""

    @abstractmethod
    async def get_health(self) -> Dict[str, Any]:
        """Return adapter subsystem health and operational status."""
        pass

    @abstractmethod
    async def get_connection_state(self, robot_id: str) -> str:
        """Return connection state ('connected', 'disconnected', 'reconnecting')."""
        pass

    @abstractmethod
    async def get_latest_telemetry(self, robot_id: str) -> TelemetrySnapshot:
        """Fetch or return the latest cached telemetry sample."""
        pass

    @abstractmethod
    async def get_occupancy_grid(self, robot_id: str) -> OccupancyGridMap:
        """Fetch the current 2D occupancy grid."""
        pass

    @abstractmethod
    async def send_cmd_vel(
        self, robot_id: str, linear_velocity: float, angular_velocity: float
    ) -> bool:
        """Send target velocities to differential-drive controller."""
        pass

    @abstractmethod
    async def submit_mission(
        self, robot_id: str, mission_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Dispatch a validated mission order."""
        pass

    @abstractmethod
    async def shutdown(self) -> None:
        """Gracefully release hardware handles, ROS nodes, or background timers."""
        pass
