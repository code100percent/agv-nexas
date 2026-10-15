from fastapi import APIRouter, Depends, HTTPException, status
from app.api.v1.robots import FLEET_ROBOTS
from app.core.security import AuthenticatedUser, check_robot_authorization, get_current_user
from app.schemas.map import OccupancyGridMap
from app.services.map_service import map_service

router = APIRouter(prefix="/robots", tags=["Maps & Spatial"])


@router.get("/{robot_id}/map", response_model=OccupancyGridMap)
async def get_robot_occupancy_grid(
    robot_id: str,
    user: AuthenticatedUser = Depends(get_current_user),
) -> OccupancyGridMap:
    """Return map metadata and 2D metric occupancy grid representation."""
    robot = next((r for r in FLEET_ROBOTS if r.id == robot_id), None)
    if not robot:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Robot with ID '{robot_id}' not found",
        )
    check_robot_authorization(user, robot.organization_id)

    try:
        return await map_service.get_robot_map(robot_id)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=str(e),
        )
