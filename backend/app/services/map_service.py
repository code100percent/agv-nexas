from app.adapters import get_robot_adapter
from app.config import settings
from app.schemas.map import OccupancyGridMap


class MapService:
    """Manages 2D metric occupancy-grid maps, caching, and payload bounds checking."""

    async def get_robot_map(self, robot_id: str) -> OccupancyGridMap:
        adapter = get_robot_adapter()
        grid = await adapter.get_occupancy_grid(robot_id)

        # Enforce payload size bounds
        cell_count = len(grid.data)
        if cell_count > settings.MAX_MAP_PAYLOAD_BYTES:
            raise ValueError(
                f"Map payload exceeds configured limit of {settings.MAX_MAP_PAYLOAD_BYTES} bytes"
            )

        return grid


map_service = MapService()
