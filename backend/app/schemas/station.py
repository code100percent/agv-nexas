from typing import Optional
from pydantic import BaseModel, Field


class Station(BaseModel):
    """Represents an operational station, dock, or landmark in the factory environment."""

    id: str
    organization_id: str
    map_id: str
    name: str = Field(..., min_length=1, max_length=100)
    station_type: str = Field(
        ...,
        description="'pickup', 'dropoff', 'charging', 'staging', or 'waypoint'",
    )
    x: float = Field(..., description="World X coordinate in meters (REP-103)")
    y: float = Field(..., description="World Y coordinate in meters (REP-103)")
    yaw: float = Field(default=0.0, description="Orientation angle in radians")
    description: Optional[str] = None
    source: str = "database"
