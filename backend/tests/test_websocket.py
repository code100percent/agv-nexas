import json
from fastapi.testclient import TestClient


def test_websocket_connection_and_heartbeat(client: TestClient):
    with client.websocket_connect("/ws/telemetry") as ws:
        # Send ping
        ws.send_text(json.dumps({"action": "ping"}))
        # Receive message
        text = ws.receive_text()
        data = json.loads(text)
        assert data["event"] in ("heartbeat", "robot.telemetry")


def test_websocket_subscribe_robot(client: TestClient):
    with client.websocket_connect("/ws/telemetry") as ws:
        # Send subscribe command
        ws.send_text(json.dumps({"action": "subscribe", "robot_id": "b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01"}))
        text = ws.receive_text()
        data = json.loads(text)
        assert data["schema_version"] == 1
        assert "payload" in data
