from app.adapters.base import RobotAdapter
from app.adapters.simulated_adapter import SimulatedRobotAdapter
from app.adapters.ros2_adapter import ROS2RobotAdapter
from app.adapters.disconnected_adapter import DisconnectedRobotAdapter
from app.config import settings

_adapter_instance: RobotAdapter | None = None


def get_robot_adapter() -> RobotAdapter:
    """Return the configured singleton RobotAdapter instance."""
    global _adapter_instance
    if _adapter_instance is None:
        mode = settings.ROBOT_ADAPTER_MODE.lower()
        if mode == "ros2":
            _adapter_instance = ROS2RobotAdapter()
        elif mode == "disconnected":
            _adapter_instance = DisconnectedRobotAdapter()
        else:
            _adapter_instance = SimulatedRobotAdapter()
    return _adapter_instance


def set_robot_adapter(adapter: RobotAdapter) -> None:
    """Explicitly override adapter (useful for testing)."""
    global _adapter_instance
    _adapter_instance = adapter


def reset_robot_adapter() -> None:
    """Reset the singleton adapter instance so next get_robot_adapter re-reads settings."""
    global _adapter_instance
    _adapter_instance = None

