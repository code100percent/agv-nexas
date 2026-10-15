import asyncio
from datetime import datetime, timezone
import json
import time
from typing import Dict, List, Optional, Set
from fastapi import WebSocket, WebSocketDisconnect
from app.adapters import get_robot_adapter
from app.config import settings
from app.core.logging import get_logger
from app.core.security import AuthenticatedUser
from app.schemas.ws_events import WebSocketEventEnvelope

logger = get_logger("connection_manager")


class ClientSession:
    """Represents an authenticated WebSocket connection with subscriptions and bounded queues."""

    def __init__(self, websocket: WebSocket, user: AuthenticatedUser) -> None:
        self.websocket = websocket
        self.user = user
        self.subscribed_robots: Set[str] = set()
        self.queue: asyncio.Queue = asyncio.Queue(maxsize=50)  # Bounded queue
        self.last_ping_time: float = time.time()
        self.is_alive = True

    async def send_event(self, event: WebSocketEventEnvelope) -> None:
        if not self.is_alive:
            return
        # If queue is full, drop oldest high-frequency telemetry to prioritize fresh data
        if self.queue.full():
            try:
                old = self.queue.get_nowait()
                self.queue.task_done()
            except asyncio.QueueEmpty:
                pass
        try:
            self.queue.put_nowait(event.model_dump_json())
        except asyncio.QueueFull:
            pass


class WebSocketConnectionManager:
    """Manages active WebSocket connections, authorization, bounded streaming, and heartbeats."""

    def __init__(self) -> None:
        self._active_sessions: List[ClientSession] = []
        self._streaming_task: Optional[asyncio.Task] = None
        self._lock = asyncio.Lock()

    async def connect(
        self, websocket: WebSocket, user: AuthenticatedUser, robot_id: Optional[str] = None
    ) -> ClientSession:
        await websocket.accept()
        session = ClientSession(websocket, user)
        if robot_id:
            session.subscribed_robots.add(robot_id)
        else:
            session.subscribed_robots.add(settings.DEFAULT_ROBOT_ID)

        async with self._lock:
            self._active_sessions.append(session)

        logger.info(
            f"WebSocket client connected: user={user.user_id}, subscribed={session.subscribed_robots}"
        )

        # Ensure background streaming loop is running
        if self._streaming_task is None or self._streaming_task.done():
            self._streaming_task = asyncio.create_task(self._broadcast_loop())

        return session

    async def disconnect(self, session: ClientSession) -> None:
        session.is_alive = False
        async with self._lock:
            if session in self._active_sessions:
                self._active_sessions.remove(session)
        logger.info(f"WebSocket client disconnected: user={session.user.user_id}")

    async def handle_client_messages(self, session: ClientSession) -> None:
        """Handle incoming control messages from client (subscriptions, ping)."""
        try:
            while session.is_alive:
                text = await session.websocket.receive_text()
                try:
                    data = json.loads(text)
                    msg_type = data.get("action") or data.get("type")

                    if msg_type == "subscribe":
                        target_id = data.get("robot_id")
                        if target_id:
                            session.subscribed_robots.add(target_id)
                            # Send initial snapshot immediately
                            adapter = get_robot_adapter()
                            telem = await adapter.get_latest_telemetry(target_id)
                            envelope = WebSocketEventEnvelope(
                                event="robot.telemetry",
                                robot_id=target_id,
                                source=telem.source,
                                payload=telem.model_dump(mode="json"),
                            )
                            await session.send_event(envelope)

                    elif msg_type == "unsubscribe":
                        target_id = data.get("robot_id")
                        if target_id in session.subscribed_robots:
                            session.subscribed_robots.remove(target_id)

                    elif msg_type == "ping":
                        session.last_ping_time = time.time()
                        pong = WebSocketEventEnvelope(
                            event="heartbeat",
                            robot_id="gateway",
                            source="gateway",
                            payload={"type": "pong", "time": time.time()},
                        )
                        await session.send_event(pong)
                except json.JSONDecodeError:
                    pass
        except WebSocketDisconnect:
            pass
        finally:
            await self.disconnect(session)

    async def pump_session_queue(self, session: ClientSession) -> None:
        """Pump items from session queue to websocket."""
        try:
            while session.is_alive:
                msg = await session.queue.get()
                await session.websocket.send_text(msg)
                session.queue.task_done()
        except WebSocketDisconnect:
            pass
        except Exception as e:
            logger.debug(f"Queue pump ended for user {session.user.user_id}: {e}")
        finally:
            await self.disconnect(session)

    async def _broadcast_loop(self) -> None:
        """Periodic background loop publishing telemetry to subscribed clients."""
        interval = 1.0 / settings.TELEMETRY_BROADCAST_HZ
        adapter = get_robot_adapter()

        while True:
            try:
                await asyncio.sleep(interval)
                if not self._active_sessions:
                    continue

                # Gather unique subscribed robot IDs
                robot_ids: Set[str] = set()
                async with self._lock:
                    for s in self._active_sessions:
                        robot_ids.update(s.subscribed_robots)

                # Fetch and fan out telemetry for each subscribed robot
                for rid in robot_ids:
                    telem = await adapter.get_latest_telemetry(rid)
                    envelope = WebSocketEventEnvelope(
                        event="robot.telemetry",
                        robot_id=rid,
                        source=telem.source,
                        payload=telem.model_dump(mode="json"),
                    )

                    async with self._lock:
                        for s in self._active_sessions:
                            if rid in s.subscribed_robots:
                                await s.send_event(envelope)
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Error in telemetry broadcast loop: {e}")
                await asyncio.sleep(1.0)


connection_manager = WebSocketConnectionManager()
