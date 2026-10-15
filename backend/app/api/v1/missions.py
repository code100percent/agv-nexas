from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from app.api.v1.robots import FLEET_ROBOTS
from app.core.security import AuthenticatedUser, check_robot_authorization, get_current_user
from app.schemas.mission import MissionCreateRequest, MissionResponse
from app.services.mission_service import mission_service

router = APIRouter(prefix="/robots", tags=["Missions"])


@router.get("/{robot_id}/missions", response_model=List[MissionResponse])
async def list_robot_missions(
    robot_id: str,
    user: AuthenticatedUser = Depends(get_current_user),
) -> List[MissionResponse]:
    """Return mission records visible to the authenticated user for this robot."""
    robot = next((r for r in FLEET_ROBOTS if r.id == robot_id), None)
    if not robot:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Robot with ID '{robot_id}' not found",
        )
    check_robot_authorization(user, robot.organization_id)

    return await mission_service.list_missions(user, robot_id=robot_id)


@router.post("/{robot_id}/missions", response_model=MissionResponse, status_code=status.HTTP_201_CREATED)
async def create_and_dispatch_mission(
    robot_id: str,
    request: MissionCreateRequest,
    user: AuthenticatedUser = Depends(get_current_user),
) -> MissionResponse:
    """Validate and request an authorized mission through the configured mission adapter."""
    robot = next((r for r in FLEET_ROBOTS if r.id == robot_id), None)
    if not robot:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Robot with ID '{robot_id}' not found",
        )
    check_robot_authorization(user, robot.organization_id)

    # Operators or higher can dispatch missions
    if user.role not in ("owner", "admin", "engineer", "operator"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Role not authorized to dispatch autonomous missions",
        )

    return await mission_service.create_and_dispatch(
        robot_id=robot_id,
        request=request,
        user=user,
    )
