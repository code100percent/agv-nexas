from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from app.api.v1.robots import FLEET_ROBOTS
from app.core.security import AuthenticatedUser, check_robot_authorization, get_current_user
from app.schemas.station import Station

router = APIRouter(tags=["Stations & Landmarks"])

# Seed factory stations matching verified PostgreSQL/Supabase database schema
FACTORY_STATIONS: List[Station] = [
    Station(
        id="d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d01",
        organization_id="a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        map_id="c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c01",
        name="Warehouse Bay A",
        station_type="pickup",
        x=2.5,
        y=3.0,
        yaw=0.0,
        description="Raw material pallet intake bay with optical alignment markings",
        source="database",
    ),
    Station(
        id="d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d02",
        organization_id="a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        map_id="c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c01",
        name="Assembly Line 4",
        station_type="dropoff",
        x=14.2,
        y=8.5,
        yaw=1.57,
        description="Main production feeder station for automated line cell 4",
        source="database",
    ),
    Station(
        id="d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d03",
        organization_id="a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        map_id="c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c01",
        name="Charging Dock 01",
        station_type="charging",
        x=1.2,
        y=1.0,
        yaw=3.14,
        description="Automated inductive floor charging station with magnetic guide strip",
        source="database",
    ),
    Station(
        id="d0eebc99-9c0b-4ef8-bb6d-6bb9bd380d04",
        organization_id="a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        map_id="c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c01",
        name="Quality Inspection 2",
        station_type="staging",
        x=8.0,
        y=12.0,
        yaw=0.78,
        description="Finished goods staging area for optical QC scanning",
        source="database",
    ),
]


@router.get("/stations", response_model=List[Station])
async def list_factory_stations(
    map_id: Optional[str] = None,
    user: AuthenticatedUser = Depends(get_current_user),
) -> List[Station]:
    """Return all verified stations visible to the authenticated tenant organization."""
    # Filter by user organization
    stations = [
        s for s in FACTORY_STATIONS
        if s.organization_id == user.organization_id or user.role == "owner"
    ]
    if map_id:
        stations = [s for s in stations if s.map_id == map_id]
    return stations


@router.get("/robots/{robot_id}/stations", response_model=List[Station])
async def list_robot_accessible_stations(
    robot_id: str,
    user: AuthenticatedUser = Depends(get_current_user),
) -> List[Station]:
    """Return stations accessible to the specified robot within authorized tenant boundaries."""
    robot = next((r for r in FLEET_ROBOTS if r.id == robot_id), None)
    if not robot:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Robot with ID '{robot_id}' not found",
        )
    check_robot_authorization(user, robot.organization_id)

    return [
        s for s in FACTORY_STATIONS
        if s.organization_id == robot.organization_id
    ]
