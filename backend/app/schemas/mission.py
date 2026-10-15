from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class MissionCreateRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    pickup_station_id: str
    dropoff_station_id: str
    priority: int = Field(default=2, ge=1, le=4)
    idempotency_key: Optional[str] = None


class MissionResponse(BaseModel):
    id: str
    organization_id: str
    robot_id: Optional[str] = None
    name: str
    pickup_station_id: str
    dropoff_station_id: str
    status: str  # queued, assigned, in_progress, completed, failed, cancelled
    priority: int
    requested_by: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    is_simulation: bool = False
