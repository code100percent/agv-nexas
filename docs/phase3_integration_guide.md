# AGV Nexus: Phase 3 Robotics Gateway & ROS 2 Integration Guide

## 1. Architecture Overview

Phase 3 introduces the production-oriented Python **FastAPI Robotics Gateway** located in `backend/` and connects it directly to the **Flutter Command Center** (`agvnexus/`) and the **ROS 2 robot software stack** (`agv_robot/`).

```
                    ┌────────────────────────┐
                    │      agvnexus/         │
                    │   (Flutter Command     │
                    │       Center)          │
                    └───────────┬────────────┘
                                │ HTTP REST / WebSocket (/ws/telemetry)
                                ▼
                    ┌────────────────────────┐
                    │       backend/         │
                    │   (FastAPI Gateway)    │
                    └───┬────────────────┬───┘
                        │                │
            ROS 2 Topics│                │ Persistence & Auth
                        ▼                ▼
         ┌─────────────────────┐   ┌──────────────────────┐
         │     agv_robot/      │   │      supabase/       │
         │ (mobile_robot stack)│   │  (PostgreSQL & RLS)  │
         └─────────────────────┘   └──────────────────────┘
```

---

## 2. Running the System Locally

### Step 1: Start the FastAPI Robotics Gateway
```bash
cd backend
python -m uvicorn app.main:app --port 8000 --host 0.0.0.0 --reload
```
* **Interactive OpenAPI Docs**: `http://localhost:8000/docs`
* **Liveness Probe**: `http://localhost:8000/health/live`
* **Readiness Probe**: `http://localhost:8000/health/ready`
* **WebSocket Stream**: `ws://localhost:8000/ws/telemetry`

### Step 2: Run the Flutter Client
```bash
cd agvnexus
flutter run -d chrome
# Or desktop:
# flutter run -d windows
```

### Step 3: Adapter Modes (`ROBOT_ADAPTER_MODE`)
Configured in `backend/.env`:
1. `simulated` (default): Deterministic differential drive simulation based on `agv_robot` URDF (wheel diameter 0.10m, track 0.35m, 900 ticks/rev).
2. `ros2`: Real DDS node subscribing to `/odom`, `/wheel_ticks`, `/scan`, `/map` and publishing to `/cmd_vel`.
3. `disconnected`: Emulates offline robot telemetry link.

---

## 3. Verified Verification Results

* **Pytest Suite (`backend/tests`)**: 23/23 tests passed.
* **Flutter Test Suite (`agvnexus/test`)**: 38/38 tests passed.
* **Flutter Static Analysis**: `flutter analyze` completed with 0 errors/warnings.
