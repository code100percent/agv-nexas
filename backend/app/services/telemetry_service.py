from datetime import datetime, timezone
import time
from typing import Dict, Optional
from app.adapters import get_robot_adapter
from app.config import settings
from app.schemas.telemetry import TelemetrySnapshot


class TelemetryService:
    """Manages high-frequency telemetry caching, staleness detection, and bounded state."""

    def __init__(self) -> None:
        self._latest_cache: Dict[str, TelemetrySnapshot] = {}
        self._last_received_time: Dict[str, float] = {}

    async def get_latest(self, robot_id: str) -> TelemetrySnapshot:
        adapter = get_robot_adapter()
        sample = await adapter.get_latest_telemetry(robot_id)

        now = time.time()
        self._latest_cache[robot_id] = sample
        self._last_received_time[robot_id] = now

        # Compute data freshness based on staleness threshold
        is_stale = (
            now - self._last_received_time.get(robot_id, 0)
            > settings.TELEMETRY_STALE_AFTER_SECONDS
        )
        if is_stale:
            sample.data_freshness = "stale"

        return sample

    def is_fresh(self, robot_id: str) -> bool:
        last_t = self._last_received_time.get(robot_id, 0)
        return (time.time() - last_t) <= settings.TELEMETRY_STALE_AFTER_SECONDS


telemetry_service = TelemetryService()
