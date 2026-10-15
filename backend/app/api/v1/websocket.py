import asyncio
from typing import Optional
from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect, status
from app.core.logging import get_logger
from app.core.security import AuthenticatedUser, verify_ws_token
from app.services.connection_manager import connection_manager

logger = get_logger("websocket_router")
router = APIRouter(tags=["WebSocket Realtime"])


async def _handle_websocket_connection(
    websocket: WebSocket,
    token: Optional[str],
    robot_id: Optional[str],
):
    try:
        user: AuthenticatedUser = verify_ws_token(token)
    except ValueError as e:
        logger.warning(f"WebSocket auth failed: {e}")
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    session = await connection_manager.connect(websocket, user, robot_id)

    # Concurrently run message listener and queue pump
    try:
        await asyncio.gather(
            connection_manager.handle_client_messages(session),
            connection_manager.pump_session_queue(session),
        )
    except Exception as e:
        logger.debug(f"WebSocket session terminated: {e}")
    finally:
        await connection_manager.disconnect(session)


@router.websocket("/ws")
async def websocket_endpoint_v1(
    websocket: WebSocket,
    token: Optional[str] = Query(None),
    robot_id: Optional[str] = Query(None),
):
    """Versioned WebSocket endpoint /api/v1/ws."""
    await _handle_websocket_connection(websocket, token, robot_id)
