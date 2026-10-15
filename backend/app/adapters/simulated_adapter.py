import asyncio
from datetime import datetime, timezone
import math
import time
from typing import Any, Dict
from app.adapters.base import RobotAdapter
from app.config import settings
from app.schemas.map import MapOrigin, OccupancyGridMap
from app.schemas.telemetry import TelemetrySnapshot


class SimulatedRobotAdapter(RobotAdapter):
    """
    Deterministic simulation adapter modeled directly after the physical differential-drive
    parameters specified in agv_robot (wheel diameter: 0.10m, track: 0.35m, 900 ticks/rev).
    """

    def __init__(self) -> None:
        self._start_time = time.time()
        # Robot kinematic state
        self._x: float = 2.5
        self._y: float = 3.0
        self._yaw: float = 0.0
        self._linear_vel: float = 0.0
        self._angular_vel: float = 0.0

        # Physical specs from agv_robot/mobile_robot_driver/encoder_odometry.py
        self.wheel_diameter: float = 0.10
        self.wheel_track: float = 0.35
        self.ticks_per_rev: float = 900.0

        # Wheel ticks counters
        self._left_ticks: int = 150000
        self._right_ticks: int = 150000

        # Battery simulation
        self._battery_percent: float = 94.5
        self._battery_voltage: float = 25.4
        self._is_charging: bool = False

        self._active_mission_id: str | None = None
        self._last_cmd_vel_time = time.time()
        self._last_update_time = time.time()

        # Cached synthetic occupancy grid
        self._map = self._build_deterministic_occupancy_grid()

    def _build_deterministic_occupancy_grid(self) -> OccupancyGridMap:
        """
        Build a representative 2D metric occupancy grid matching the factory layout
        (400x300 cells at 0.05m = 20m x 15m factory floor, or a fast 100x80 representation for streaming).
        Here we generate a 120x80 grid at 0.05m resolution (6m x 4m corridor / bay).
        """
        width = 120
        height = 80
        resolution = 0.05

        # Initialize with free space (0)
        data = [0] * (width * height)

        # Draw outer perimeter walls (100 = occupied)
        for c in range(width):
            data[0 * width + c] = 100
            data[(height - 1) * width + c] = 100
        for r in range(height):
            data[r * width + 0] = 100
            data[r * width + (width - 1)] = 100

        # Draw rectangular interior storage obstacles
        # Obstacle 1: Bay columns at (x=2.0-3.5m, y=1.5-2.0m) -> col 40..70, row 30..40
        for r in range(30, 40):
            for c in range(40, 70):
                data[r * width + c] = 100

        # Obstacle 2: Staging crate at (x=4.0-5.0m, y=2.5-3.2m) -> col 80..100, row 50..64
        for r in range(50, 64):
            for c in range(80, 100):
                data[r * width + c] = 100

        # Unexplored / unknown areas (-1) in corners
        for r in range(1, 10):
            for c in range(1, 15):
                data[r * width + c] = -1

        return OccupancyGridMap(
            map_id=settings.DEFAULT_MAP_ID,
            robot_id=settings.DEFAULT_ROBOT_ID,
            frame_id="map",
            width=width,
            height=height,
            resolution=resolution,
            origin=MapOrigin(x=0.0, y=0.0, yaw=0.0),
            timestamp=datetime.now(timezone.utc),
            encoding="int8_array",
            data=data,
        )

    def _step_simulation(self) -> None:
        """Integrate differential-drive dead reckoning step."""
        now = time.time()
        dt = now - self._last_update_time
        self._last_update_time = now

        # Auto stop if no teleop command in 1.5 seconds (Deadman safety)
        if now - self._last_cmd_vel_time > 1.5:
            # If in mission, keep gentle pathing motion, else stop
            if self._active_mission_id:
                self._linear_vel = 0.25
                self._angular_vel = 0.05 * math.sin(now * 0.5)
            else:
                self._linear_vel = 0.0
                self._angular_vel = 0.0

        # Compute position updates
        if abs(self._angular_vel) < 1e-6:
            self._x += self._linear_vel * dt * math.cos(self._yaw)
            self._y += self._linear_vel * dt * math.sin(self._yaw)
        else:
            radius = self._linear_vel / self._angular_vel
            new_yaw = self._yaw + self._angular_vel * dt
            self._x += radius * (math.sin(new_yaw) - math.sin(self._yaw))
            self._y -= radius * (math.cos(new_yaw) - math.cos(self._yaw))
            self._yaw = new_yaw

        # Normalize yaw to [-pi, pi]
        self._yaw = math.atan2(math.sin(self._yaw), math.cos(self._yaw))

        # Update wheel ticks
        # v_left = v - w * L / 2; v_right = v + w * L / 2
        v_left = self._linear_vel - (self._angular_vel * self.wheel_track / 2.0)
        v_right = self._linear_vel + (self._angular_vel * self.wheel_track / 2.0)

        meters_per_tick = (math.pi * self.wheel_diameter) / self.ticks_per_rev
        self._left_ticks = int(
            (self._left_ticks + (v_left * dt / meters_per_tick)) % (2**32)
        )
        self._right_ticks = int(
            (self._right_ticks + (v_right * dt / meters_per_tick)) % (2**32)
        )

        # Battery discharge/charge
        if self._is_charging:
            self._battery_percent = min(100.0, self._battery_percent + 0.1 * dt)
        else:
            consumption = 0.005 + (0.02 if abs(self._linear_vel) > 0.01 else 0.0)
            self._battery_percent = max(0.0, self._battery_percent - consumption * dt)

        self._battery_voltage = 22.0 + (self._battery_percent / 100.0) * 4.2

    async def get_health(self) -> Dict[str, Any]:
        return {
            "status": "healthy",
            "mode": "simulated",
            "uptime_seconds": time.time() - self._start_time,
            "simulated_robot_id": settings.DEFAULT_ROBOT_ID,
            "message": "Deterministic differential-drive robot simulator active",
        }

    async def get_connection_state(self, robot_id: str) -> str:
        return "connected"

    async def get_latest_telemetry(self, robot_id: str) -> TelemetrySnapshot:
        self._step_simulation()
        now = datetime.now(timezone.utc)

        return TelemetrySnapshot(
            robot_id=robot_id,
            timestamp=now,
            source="simulated",
            connection_state="connected",
            data_freshness="fresh",
            position_x=round(self._x, 4),
            position_y=round(self._y, 4),
            position_z=0.0,
            yaw=round(self._yaw, 4),
            linear_velocity=round(self._linear_vel, 3),
            angular_velocity=round(self._angular_vel, 3),
            left_wheel_ticks=self._left_ticks,
            right_wheel_ticks=self._right_ticks,
            battery_percentage=round(self._battery_percent, 1),
            battery_voltage=round(self._battery_voltage, 2),
            is_charging=self._is_charging,
            robot_operating_state="navigating" if self._active_mission_id else "idle",
            localization_confidence=0.98,
            active_mission_id=self._active_mission_id,
            active_faults=[],
        )

    async def get_occupancy_grid(self, robot_id: str) -> OccupancyGridMap:
        self._map.timestamp = datetime.now(timezone.utc)
        return self._map

    async def send_cmd_vel(
        self, robot_id: str, linear_velocity: float, angular_velocity: float
    ) -> bool:
        self._linear_vel = float(linear_velocity)
        self._angular_vel = float(angular_velocity)
        self._last_cmd_vel_time = time.time()
        return True

    async def submit_mission(
        self, robot_id: str, mission_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        mission_id = mission_data.get("id") or f"sim-mission-{int(time.time())}"
        self._active_mission_id = mission_id
        return {
            "status": "accepted",
            "mission_id": mission_id,
            "robot_id": robot_id,
            "adapter": "simulated",
            "message": "Simulated mission accepted and navigation initialized",
        }

    async def shutdown(self) -> None:
        self._linear_vel = 0.0
        self._angular_vel = 0.0
