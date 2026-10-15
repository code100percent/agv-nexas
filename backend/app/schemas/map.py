from datetime import datetime
from typing import Dict, List, Tuple
from pydantic import BaseModel, Field, field_validator
import math


class MapOrigin(BaseModel):
    x: float = 0.0
    y: float = 0.0
    yaw: float = 0.0


class OccupancyGridMap(BaseModel):
    """Represents a 2D metric occupancy grid conforming to nav_msgs/OccupancyGrid."""

    map_id: str
    robot_id: str
    frame_id: str = "map"
    width: int = Field(..., gt=0, description="Width in cells (columns)")
    height: int = Field(..., gt=0, description="Height in cells (rows)")
    resolution: float = Field(..., gt=0.0, description="Meters per grid cell")
    origin: MapOrigin
    timestamp: datetime
    encoding: str = "int8_array"
    data: List[int] = Field(
        ...,
        description="Row-major 1D array of occupancy values: -1=unknown, 0=free, 100=occupied",
    )

    @field_validator("data")
    @classmethod
    def validate_cell_count(cls, v: List[int], info) -> List[int]:
        width = info.data.get("width")
        height = info.data.get("height")
        if width and height:
            expected = width * height
            if len(v) != expected:
                raise ValueError(
                    f"Occupancy grid cell count mismatch: got {len(v)}, expected {expected} ({width}x{height})"
                )
        return v

    def world_to_grid(self, world_x: float, world_y: float) -> Tuple[int, int]:
        """Convert world coordinates (meters) to grid indices (col, row)."""
        # Offset by origin and rotate if origin has yaw
        dx = world_x - self.origin.x
        dy = world_y - self.origin.y
        cos_theta = math.cos(-self.origin.yaw)
        sin_theta = math.sin(-self.origin.yaw)

        rx = dx * cos_theta - dy * sin_theta
        ry = dx * sin_theta + dy * cos_theta

        col = int(math.floor(rx / self.resolution))
        row = int(math.floor(ry / self.resolution))
        return col, row

    def grid_to_world(self, col: int, row: int) -> Tuple[float, float]:
        """Convert grid cell center (col, row) to world coordinates (meters)."""
        rx = (col + 0.5) * self.resolution
        ry = (row + 0.5) * self.resolution
        cos_theta = math.cos(self.origin.yaw)
        sin_theta = math.sin(self.origin.yaw)

        world_x = rx * cos_theta - ry * sin_theta + self.origin.x
        world_y = rx * sin_theta + ry * cos_theta + self.origin.y
        return world_x, world_y
