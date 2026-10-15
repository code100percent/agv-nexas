from datetime import datetime, timezone
import uuid
from typing import Dict, List, Optional
from fastapi import HTTPException, status
from app.adapters import get_robot_adapter
from app.config import settings
from app.core.logging import get_logger
from app.core.security import AuthenticatedUser
from app.schemas.mission import MissionCreateRequest, MissionResponse

logger = get_logger("mission_service")


class MissionService:
    """Handles mission order validation, idempotency, dispatch, and state tracking."""

    def __init__(self) -> None:
        self._missions: Dict[str, MissionResponse] = {}
        self._idempotency_map: Dict[str, str] = {}  # key -> mission_id

        # Prepopulate sample missions from Supabase seed
        seed_id_1 = "e0eebc99-9c0b-4ef8-bb6d-6bb9bd380e01"
        self._missions[seed_id_1] = MissionResponse(
            id=seed_id_1,
            organization_id=settings.DEFAULT_ORG_ID,
            robot_id=settings.DEFAULT_ROBOT_ID,
            name="Pallet Staging Transfer",
            pickup_station_id="d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d01",
            dropoff_station_id="d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d02",
            status="in_progress",
            priority=2,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
            started_at=datetime.now(timezone.utc),
            is_simulation=True,
        )

    async def list_missions(
        self, user: AuthenticatedUser, robot_id: Optional[str] = None
    ) -> List[MissionResponse]:
        # Filter by organization
        results = [
            m for m in self._missions.values()
            if m.organization_id == user.organization_id
        ]
        if robot_id:
            results = [m for m in results if m.robot_id == robot_id]
        return results

    async def create_and_dispatch(
        self,
        robot_id: str,
        request: MissionCreateRequest,
        user: AuthenticatedUser,
    ) -> MissionResponse:
        # Check idempotency
        if request.idempotency_key and request.idempotency_key in self._idempotency_map:
            cached_id = self._idempotency_map[request.idempotency_key]
            logger.info(f"Duplicate mission request suppressed via idempotency key: {request.idempotency_key}")
            return self._missions[cached_id]

        # Station validity
        if request.pickup_station_id == request.dropoff_station_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Pickup station and dropoff station cannot be identical",
            )

        mission_id = str(uuid.uuid4())
        adapter = get_robot_adapter()

        # Submit to adapter
        try:
            result = await adapter.submit_mission(
                robot_id=robot_id,
                mission_data={
                    "id": mission_id,
                    "pickup": request.pickup_station_id,
                    "dropoff": request.dropoff_station_id,
                    "priority": request.priority,
                },
            )
        except ConnectionError as e:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"Robot is disconnected: {e}",
            )
        except Exception as e:
            logger.error(f"Failed to submit mission to adapter: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to dispatch mission to robot controller",
            )

        now = datetime.now(timezone.utc)
        mission = MissionResponse(
            id=mission_id,
            organization_id=user.organization_id,
            robot_id=robot_id,
            name=request.name,
            pickup_station_id=request.pickup_station_id,
            dropoff_station_id=request.dropoff_station_id,
            status="in_progress",
            priority=request.priority,
            requested_by=user.user_id,
            created_at=now,
            updated_at=now,
            started_at=now,
            is_simulation=(settings.ROBOT_ADAPTER_MODE == "simulated"),
        )

        self._missions[mission_id] = mission
        if request.idempotency_key:
            self._idempotency_map[request.idempotency_key] = mission_id

        logger.info(f"Mission {mission_id} dispatched to robot {robot_id} by {user.user_id}")
        return mission


mission_service = MissionService()
