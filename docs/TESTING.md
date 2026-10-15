# AGV Nexus: Comprehensive Testing Strategy & Verification Guide

**Document Version**: 1.0.0 (Phase 5 Production Readiness)  
**Classification**: Quality Assurance & Verification Specification  

---

## 1. Testing Philosophy & Separation of Concerns

AGV Nexus adheres strictly to automated verification boundaries:
- **Unit & Widget Tests**: Isolated, deterministic, with mock HTTP clients and zero network dependency.
- **Backend API & Failure Tests**: Fast Pytest test client exercising real ASGI middleware, JWT validation, role checks, and error responses.
- **Hardware Boundary**: Clear separation between simulated robot adapters and physical AMR hardware. Simulation results are **never** reported as physical hardware verification.

---

## 2. Test Execution Commands

### 2.1 Backend Pytest Suite
```bash
cd backend

# Execute all 38 backend tests
pytest -v

# Run with coverage report
pytest --cov=app --cov-report=term-missing tests/

# Run specifically failure and security tests
pytest -v tests/test_failure_scenarios.py tests/test_auth.py
```
*Current Status: 38/38 passing (100% pass rate).*

### 2.2 Flutter Test Suite
```bash
cd agvnexus

# Execute all 45 Flutter unit, widget, and failure handling tests
flutter test

# Run with detailed progress
flutter test --reporter=expanded

# Run specific failure handling tests
flutter test test/features/robots/failure_handling_test.dart
```
*Current Status: 45/45 passing (100% pass rate).*

---

## 3. Test Layer Inventory & Coverage

| Test Layer | Test Count | Location | Covered Scenarios |
|---|---|---|---|
| **Backend Auth & Security** | 4 | `backend/tests/test_auth.py` | Missing auth, malformed headers, expired tokens, cross-tenant isolation. |
| **Backend Coordinate Transforms** | 5 | `backend/tests/test_coordinate_transforms.py` | ROS 2 REP-103 $\to$ Three.js, cardinal quaternions, yaw normalization. |
| **Backend Map Transforms** | 5 | `backend/tests/test_map_transforms.py` | Occupancy grid origin, center, corners, rotated grid, out-of-bounds rejection. |
| **Backend Missions & Idempotency** | 4 | `backend/tests/test_missions.py` | List missions, create mission, duplicate idempotency key, identical stations rejection. |
| **Backend Robots & Teleop** | 6 | `backend/tests/test_robots_api.py` | List robots, status, telemetry, connection state, teleop dispatch, 404 handling. |
| **Backend Stations** | 3 | `backend/tests/test_stations.py` | Factory stations, accessible stations per robot, auth checks. |
| **Backend WebSockets & Telemetry** | 2 | `backend/tests/test_websocket.py` | Connection handshake, periodic ping/pong, topic subscriptions. |
| **Backend Failure Scenarios** | 6 | `backend/tests/test_failure_scenarios.py` | Log secret redaction, 2MB payload ceiling, viewer role teleop/mission rejection, degraded adapter health, idempotency collision. |
| **Backend Health & Static** | 3 | `backend/tests/test_health.py`, `test_viewer_static.py` | Liveness, readiness, static Three.js viewer mount. |
| **Flutter App Navigation & UI** | 19 | `agvnexus/test/app/navigation_test.dart` | Unauthenticated redirect to `/sign-in`, desktop NavigationRail, responsive layout. |
| **Flutter Digital Twin & Fallback** | 14 | `agvnexus/test/features/digital_twin/` | 3D screen mount, toggle between 3D and 2D failsafe painter, repaint triggers. |
| **Flutter Models & Failure** | 12 | `agvnexus/test/features/` | Supabase robot parsing, stale last_seen_at, telemetry parsing, null handling, 503 gateway handling, 404 handling, teleop false on failure. |

---

## 4. Simulation vs. Hardware Testing

### Deterministic Simulation Engine
- Active when `ROBOT_ADAPTER_MODE=simulated`.
- Generates continuous 10 Hz kinematic odometry for a differential-drive robot (`Titan-01`) navigating between factory stations.
- Provides mock LiDAR scan range arrays, battery discharge/charge simulation, and real-time heading angles.

### Physical Hardware Verification Requirements (Gate 6)
Physical hardware verification requires:
1. Physical AMR unit powered on with safe dual-channel hardware E-stop active.
2. ROS 2 Humble network on dedicated robot subnet (`ROS_DOMAIN_ID` matching robot).
3. 2D laser safety scanner clear zones verified.
4. Physical obstacle testing under supervised low-speed condition ($\le 0.3 \text{ m/s}$).

> [!WARNING]
> Because physical AMR hardware is not connected to this test environment, **Release Gate 6 is marked: Not Verified / Pending Physical Hardware Access**.
