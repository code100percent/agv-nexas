import time
from datetime import datetime, timezone
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from app.adapters import get_robot_adapter
from app.config import settings
from app.core.security import AuthenticatedUser, check_robot_authorization, get_current_user
from app.schemas.robot import (
    RobotConnectionResponse,
    RobotRecord,
    RobotStatusResponse,
    TeleopCommand,
)
from app.schemas.telemetry import TelemetrySnapshot
from app.services.telemetry_service import telemetry_service

router = APIRouter(prefix="/robots", tags=["Robots & Telemetry"])

# In-memory registry of fleet robots (matching Supabase seed)
FLEET_ROBOTS = [
    RobotRecord(
        id=settings.DEFAULT_ROBOT_ID,
        organization_id=settings.DEFAULT_ORG_ID,
        name="Titan-01",
        robot_code="AGV-01",
        description="Heavy-duty differential drive pallet mover with safety LiDAR",
        robot_type="differential_drive",
        max_payload_kg=15.0,
        last_seen_at=datetime.now(timezone.utc),
    ),
    RobotRecord(
        id="b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b02",
        organization_id=settings.DEFAULT_ORG_ID,
        name="Atlas-02",
        robot_code="AGV-02",
        description="High-speed line supply AMR with optical dock guidance",
        robot_type="differential_drive",
        max_payload_kg=15.0,
        last_seen_at=datetime.now(timezone.utc),
    ),
    RobotRecord(
        id="b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b04",
        organization_id=settings.DEFAULT_ORG_ID,
        name="Hermes-04",
        robot_code="AGV-04",
        description="Precision parts delivery AGV with top roller deck",
        robot_type="differential_drive",
        max_payload_kg=10.0,
        last_seen_at=datetime.now(timezone.utc),
    ),
]


@router.get("", response_model=List[RobotRecord])
async def list_robots(
    user: AuthenticatedUser = Depends(get_current_user),
) -> List[RobotRecord]:
    """Return the authenticated user's authorized robot records."""
    # Enforce tenant isolation: return robots belonging to the user's organization
    return [r for r in FLEET_ROBOTS if r.organization_id == user.organization_id]


@router.get("/{robot_id}/status", response_model=RobotStatusResponse)
async def get_robot_status(
    robot_id: str,
    user: AuthenticatedUser = Depends(get_current_user),
) -> RobotStatusResponse:
    """Return robot connectivity, operating state, latest telemetry timestamp, and data freshness."""
    robot = next((r for r in FLEET_ROBOTS if r.id == robot_id), None)
    if not robot:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Robot with ID '{robot_id}' not found",
        )
    check_robot_authorization(user, robot.organization_id)

    adapter = get_robot_adapter()
    conn_state = await adapter.get_connection_state(robot_id)
    telem = await telemetry_service.get_latest(robot_id)

    return RobotStatusResponse(
        robot_id=robot_id,
        connection_state=conn_state,
        operating_mode=telem.robot_operating_state or "idle",
        data_freshness=telem.data_freshness,
        source=telem.source,
        last_heartbeat=telem.timestamp,
        active_mission_id=telem.active_mission_id,
        has_faults=len(telem.active_faults) > 0,
        active_faults=telem.active_faults,
    )


@router.get("/{robot_id}/telemetry", response_model=TelemetrySnapshot)
async def get_robot_telemetry(
    robot_id: str,
    user: AuthenticatedUser = Depends(get_current_user),
) -> TelemetrySnapshot:
    """Return a validated latest telemetry snapshot."""
    robot = next((r for r in FLEET_ROBOTS if r.id == robot_id), None)
    if not robot:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Robot with ID '{robot_id}' not found",
        )
    check_robot_authorization(user, robot.organization_id)

    return await telemetry_service.get_latest(robot_id)


@router.get("/{robot_id}/connection", response_model=RobotConnectionResponse)
async def get_robot_connection(
    robot_id: str,
    user: AuthenticatedUser = Depends(get_current_user),
) -> RobotConnectionResponse:
    """Return the robot gateway connection state and last successful heartbeat."""
    robot = next((r for r in FLEET_ROBOTS if r.id == robot_id), None)
    if not robot:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Robot with ID '{robot_id}' not found",
        )
    check_robot_authorization(user, robot.organization_id)

    adapter = get_robot_adapter()
    conn_state = await adapter.get_connection_state(robot_id)
    telem = await telemetry_service.get_latest(robot_id)

    return RobotConnectionResponse(
        robot_id=robot_id,
        connection_state=conn_state,
        source=telem.source,
        last_heartbeat=telem.timestamp,
        gateway_uptime_seconds=3600.0,
        topics_subscribed=["/odom", "/scan", "/wheel_ticks", "/map"],
        ping_latency_ms=1.5 if conn_state == "connected" else 999.0,
    )


@router.post("/{robot_id}/teleop")
async def send_teleop_command(
    robot_id: str,
    cmd: TeleopCommand,
    user: AuthenticatedUser = Depends(get_current_user),
):
    """
    Send manual differential-drive velocity commands to the robot controller.
    Maps to ROS 2 geometry_msgs/Twist on /cmd_vel.
    """
    robot = next((r for r in FLEET_ROBOTS if r.id == robot_id), None)
    if not robot:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Robot with ID '{robot_id}' not found",
        )
    check_robot_authorization(user, robot.organization_id)

    # Only authorized operational roles may issue manual teleop movement commands
    if user.role not in ("owner", "admin", "engineer", "operator"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Role not authorized to issue manual teleop commands",
        )

    adapter = get_robot_adapter()

    success = await adapter.send_cmd_vel(
        robot_id, cmd.linear_velocity, cmd.angular_velocity
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Failed to dispatch velocity command to robot adapter",
        )

    return {
        "status": "command_sent",
        "robot_id": robot_id,
        "linear_velocity": cmd.linear_velocity,
        "angular_velocity": cmd.angular_velocity,
    }
