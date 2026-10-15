from fastapi import APIRouter
from app.api.v1.robots import router as robots_router
from app.api.v1.maps import router as maps_router
from app.api.v1.missions import router as missions_router
from app.api.v1.stations import router as stations_router
from app.api.v1.websocket import router as ws_router

api_v1_router = APIRouter(prefix="/api/v1")
api_v1_router.include_router(robots_router)
api_v1_router.include_router(maps_router)
api_v1_router.include_router(missions_router)
api_v1_router.include_router(stations_router)
api_v1_router.include_router(ws_router)
