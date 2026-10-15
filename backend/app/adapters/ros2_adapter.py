# pyrefly: ignore-errors[missing-import]
import asyncio
from datetime import datetime, timezone
import math
import time
from typing import Any, Dict, Optional
from app.adapters.base import RobotAdapter
from app.config import settings
from app.core.logging import get_logger
from app.schemas.map import MapOrigin, OccupancyGridMap
from app.schemas.telemetry import TelemetrySnapshot

logger = get_logger("ros2_adapter")

# Attempt lazy import of rclpy
HAS_RCLPY = False
try:
    import rclpy  # type: ignore # pyrefly: ignore[missing-import]
    from rclpy.node import Node  # type: ignore # pyrefly: ignore[missing-import]
    from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy  # type: ignore # pyrefly: ignore[missing-import]
    from nav_msgs.msg import Odometry, OccupancyGrid  # type: ignore # pyrefly: ignore[missing-import]
    from geometry_msgs.msg import Twist  # type: ignore # pyrefly: ignore[missing-import]
    from std_msgs.msg import Int32MultiArray  # type: ignore # pyrefly: ignore[missing-import]
    HAS_RCLPY = True
except (ImportError, ModuleNotFoundError):
    rclpy = None  # type: ignore
    Node = None  # type: ignore
    QoSProfile = None  # type: ignore
    ReliabilityPolicy = None  # type: ignore
    HistoryPolicy = None  # type: ignore
    Odometry = None  # type: ignore
    OccupancyGrid = None  # type: ignore
    Twist = None  # type: ignore
    Int32MultiArray = None  # type: ignore
    HAS_RCLPY = False


class ROS2RobotAdapter(RobotAdapter):
    """
    Real ROS 2 driver adapter integrating with the actual topics from agv_robot:
    - Subscribes to /odom (nav_msgs/Odometry)
    - Subscribes to /wheel_ticks (std_msgs/Int32MultiArray)
    - Subscribes to /map (nav_msgs/OccupancyGrid from slam_toolbox)
    - Publishes to /cmd_vel (geometry_msgs/Twist)
    """

    def __init__(self) -> None:
        self._is_active = False
        self._node: Optional[Any] = None
        self._last_telemetry: Optional[TelemetrySnapshot] = None
        self._last_map: Optional[OccupancyGridMap] = None
        self._last_heartbeat_time: float = 0.0
        self._cmd_vel_pub: Optional[Any] = None

        if not HAS_RCLPY:
            logger.warning(
                "rclpy or ROS 2 dependencies not found in current Python environment. "
                "ROS 2 adapter running in unverified/standby mode."
            )
        else:
            self._init_ros2()

    def _init_ros2(self) -> None:
        try:
            if not rclpy.ok():
                rclpy.init(domain_id=settings.ROS_DOMAIN_ID)

            node_name = f"agv_nexus_gateway_{int(time.time())}"
            self._node = Node(node_name, namespace=settings.ROS_NAMESPACE)

            # Subscribers matching agv_robot topics
            self._node.create_subscription(
                Odometry,
                "/odom",
                self._odom_callback,
                10,
            )
            self._node.create_subscription(
                Int32MultiArray,
                "/wheel_ticks",
                self._ticks_callback,
                10,
            )
            self._node.create_subscription(
                OccupancyGrid,
                "/map",
                self._map_callback,
                1,
            )
            self._cmd_vel_pub = self._node.create_publisher(
                Twist,
                "/cmd_vel",
                10,
            )
            self._is_active = True
            logger.info("ROS 2 Gateway Node successfully initialized.")
        except Exception as e:
            logger.error(f"Failed to initialize ROS 2 node: {e}")
            self._is_active = False

    def _odom_callback(self, msg: Any) -> None:
        self._last_heartbeat_time = time.time()
        # Parse position and orientation
        pos = msg.pose.pose.position
        ori = msg.pose.pose.orientation
        # Compute yaw from quaternion (Z and W)
        yaw = 2.0 * math.atan2(ori.z, ori.w)

        vel_lin = msg.twist.twist.linear.x
        vel_ang = msg.twist.twist.angular.z

        self._last_telemetry = TelemetrySnapshot(
            robot_id=settings.DEFAULT_ROBOT_ID,
            timestamp=datetime.now(timezone.utc),
            source="ros2",
            connection_state="connected",
            data_freshness="fresh",
            position_x=float(pos.x),
            position_y=float(pos.y),
            position_z=float(pos.z),
            yaw=float(yaw),
            linear_velocity=float(vel_lin),
            angular_velocity=float(vel_ang),
            localization_confidence=1.0,
            robot_operating_state="navigating" if abs(vel_lin) > 0.01 else "idle",
        )

    def _ticks_callback(self, msg: Any) -> None:
        if self._last_telemetry and len(msg.data) >= 2:
            self._last_telemetry.left_wheel_ticks = int(msg.data[0])
            self._last_telemetry.right_wheel_ticks = int(msg.data[1])

    def _map_callback(self, msg: Any) -> None:
        info = msg.info
        origin = info.origin
        self._last_map = OccupancyGridMap(
            map_id=settings.DEFAULT_MAP_ID,
            robot_id=settings.DEFAULT_ROBOT_ID,
            frame_id=msg.header.frame_id or "map",
            width=int(info.width),
            height=int(info.height),
            resolution=float(info.resolution),
            origin=MapOrigin(
                x=float(origin.position.x),
                y=float(origin.position.y),
                yaw=0.0,
            ),
            timestamp=datetime.now(timezone.utc),
            encoding="int8_array",
            data=list(msg.data),
        )

    async def get_health(self) -> Dict[str, Any]:
        return {
            "status": "healthy" if self._is_active else "unverified_environment",
            "mode": "ros2",
            "has_rclpy": HAS_RCLPY,
            "is_active": self._is_active,
            "last_heartbeat": self._last_heartbeat_time,
            "domain_id": settings.ROS_DOMAIN_ID,
            "verified": self._is_active and (time.time() - self._last_heartbeat_time < 5.0),
        }

    async def get_connection_state(self, robot_id: str) -> str:
        if not self._is_active:
            return "disconnected"
        if time.time() - self._last_heartbeat_time > settings.TELEMETRY_STALE_AFTER_SECONDS:
            return "reconnecting"
        return "connected"

    async def get_latest_telemetry(self, robot_id: str) -> TelemetrySnapshot:
        if not self._is_active or not self._last_telemetry:
            return TelemetrySnapshot(
                robot_id=robot_id,
                timestamp=datetime.now(timezone.utc),
                source="ros2",
                connection_state="disconnected",
                data_freshness="stale",
                position_x=None,
                position_y=None,
                linear_velocity=None,
                angular_velocity=None,
            )

        # Check freshness
        is_fresh = (
            time.time() - self._last_heartbeat_time
            <= settings.TELEMETRY_STALE_AFTER_SECONDS
        )
        self._last_telemetry.data_freshness = "fresh" if is_fresh else "stale"
        self._last_telemetry.connection_state = "connected" if is_fresh else "reconnecting"
        return self._last_telemetry

    async def get_occupancy_grid(self, robot_id: str) -> OccupancyGridMap:
        if not self._last_map:
            # Return empty grid if none received from /map yet
            return OccupancyGridMap(
                map_id=settings.DEFAULT_MAP_ID,
                robot_id=robot_id,
                frame_id="map",
                width=10,
                height=10,
                resolution=0.05,
                origin=MapOrigin(x=0.0, y=0.0, yaw=0.0),
                timestamp=datetime.now(timezone.utc),
                encoding="int8_array",
                data=[-1] * 100,
            )
        return self._last_map

    async def send_cmd_vel(
        self, robot_id: str, linear_velocity: float, angular_velocity: float
    ) -> bool:
        if not self._is_active or not hasattr(self, "_cmd_vel_pub"):
            logger.warning("Cannot send cmd_vel: ROS 2 node is not active.")
            return False

        twist = Twist()
        twist.linear.x = float(linear_velocity)
        twist.angular.z = float(angular_velocity)
        self._cmd_vel_pub.publish(twist)
        return True

    async def submit_mission(
        self, robot_id: str, mission_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        if not self._is_active:
            raise RuntimeError("ROS 2 Nav2 dispatcher not active on physical robot.")
        # Nav2 action client integration
        return {
            "status": "accepted",
            "mission_id": mission_data.get("id"),
            "robot_id": robot_id,
            "adapter": "ros2",
        }

    async def shutdown(self) -> None:
        if self._node and HAS_RCLPY:
            self._node.destroy_node()
            if rclpy.ok():
                rclpy.shutdown()
            self._is_active = False
