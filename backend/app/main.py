from contextlib import asynccontextmanager
from pathlib import Path
import time
import uuid
from typing import Optional
from fastapi import FastAPI, Request, Response, WebSocket, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from app.adapters import get_robot_adapter
from app.api.v1.router import api_v1_router
from app.api.v1.websocket import _handle_websocket_connection
from app.config import settings
from app.core.logging import get_logger, request_id_ctx, setup_logging

setup_logging()
logger = get_logger("main")


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info(
        f"Starting {settings.APP_NAME} v{settings.APP_VERSION} [mode: {settings.ROBOT_ADAPTER_MODE}]"
    )
    adapter = get_robot_adapter()
    health = await adapter.get_health()
    logger.info(f"Initialized robot adapter health: {health}")
    yield
    # Shutdown
    logger.info("Shutting down AGV Nexus Gateway...")
    await adapter.shutdown()
    logger.info("Shutdown complete.")


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="Industrial Robotics Gateway connecting AGV Nexus Flutter UI to ROS 2 AMRs.",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
)


# Maximum allowable JSON payload size (2 MB) to prevent resource exhaustion
MAX_REQUEST_BODY_BYTES = 2 * 1024 * 1024


@app.middleware("http")
async def security_and_request_id_middleware(request: Request, call_next):
    # Enforce request payload size limit if Content-Length is provided
    content_length = request.headers.get("content-length")
    if content_length and int(content_length) > MAX_REQUEST_BODY_BYTES:
        return JSONResponse(
            status_code=status.HTTP_413_CONTENT_TOO_LARGE,
            content={"detail": "Request payload exceeds maximum allowed size (2 MB)"},
        )


    req_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
    token = request_id_ctx.set(req_id)
    start_time = time.time()
    try:
        response: Response = await call_next(request)
        duration = round((time.time() - start_time) * 1000, 2)
        # Observability and Security Headers
        response.headers["X-Request-ID"] = req_id
        response.headers["X-Response-Time-Ms"] = str(duration)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "SAMEORIGIN"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        return response
    finally:
        request_id_ctx.reset(token)



# Health Endpoints
@app.get("/health/live", tags=["Health"])
async def liveness_check():
    """Liveness probe: verifies the process is running without checking external dependencies."""
    return {
        "status": "alive",
        "service": settings.APP_NAME,
        "timestamp": time.time(),
    }


@app.get("/health/ready", tags=["Health"])
async def readiness_check():
    """Readiness probe: reports subsystem readiness, adapter status, and memory state."""
    adapter = get_robot_adapter()
    adapter_health = await adapter.get_health()
    is_ready = adapter_health.get("status") in ("healthy", "unverified_environment")

    return JSONResponse(
        status_code=status.HTTP_200_OK if is_ready else status.HTTP_503_SERVICE_UNAVAILABLE,
        content={
            "status": "ready" if is_ready else "not_ready",
            "environment": settings.APP_ENV,
            "adapter_mode": settings.ROBOT_ADAPTER_MODE,
            "adapter_health": adapter_health,
            "supabase_configured": bool(settings.SUPABASE_URL and settings.SUPABASE_ANON_KEY),
        },
    )


# WebSocket Root Endpoint (matching Flutter wsBaseUrl = 'ws://localhost:8000/ws/telemetry')
@app.websocket("/ws/telemetry")
async def root_telemetry_websocket(
    websocket: WebSocket,
    token: Optional[str] = None,
    robot_id: Optional[str] = None,
):
    """Real-time authenticated telemetry stream."""
    await _handle_websocket_connection(websocket, token, robot_id)


# Include API v1 Router
app.include_router(api_v1_router)

# Mount 3D Digital Twin Three.js WebGL Viewer
viewer_path = Path(__file__).resolve().parent.parent.parent / "viewer"
if not viewer_path.exists():
    viewer_path.mkdir(parents=True, exist_ok=True)

app.mount("/viewer", StaticFiles(directory=str(viewer_path), html=True), name="viewer")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.API_HOST,
        port=settings.API_PORT,
        reload=(settings.APP_ENV == "development"),
    )
