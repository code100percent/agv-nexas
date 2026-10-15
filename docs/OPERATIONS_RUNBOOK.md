# AGV Nexus: Operations & Incident Response Runbook

**Document Version**: 1.0.0 (Phase 5 Production Readiness)  
**Target Audience**: DevOps Engineers, Site Reliability Engineers, Plant Operators  
**Classification**: Operational Standard Operating Procedure (SOP)  

---

## 1. Quick Reference: Incident Triage Matrix

| Symptom | Severity | Probable Cause | Immediate Action |
|---|---|---|---|
| Gateway returns HTTP 503 on `/health/ready` | **P1 - High** | Robot adapter lost connectivity or ROS 2 daemon died. | Check container logs: `docker logs agvnexus-gateway`. Verify robot network ping. |
| Dashboard displays "STALE TELEMETRY" (Amber) | **P2 - Medium** | Robot heartbeat missed for $> 5\text{s}$. Network congestion or robot CPU saturation. | Verify robot Wi-Fi RSSI. Do not issue new missions until freshness resets to "Live". |
| Dashboard displays "DISCONNECTED" (Red) | **P1 - High** | Telemetry link severed ($> 10\text{s}$) or robot powered down. | Dispatch floor operator to inspect physical AGV. Confirm physical E-stop is not engaged. |
| WebSocket reconnecting indefinitely | **P2 - Medium** | Gateway restarted, firewall blocked WS upgrade, or expired auth token. | Check browser developer console. Re-authenticate via `/sign-in` if token expired. |
| 3D Viewer renders blank canvas | **P3 - Low** | WebGL context lost or hardware acceleration disabled. | Toggle "2D Failsafe" switch in top HUD. Switch view to native 2D Isometric Painter. |
| Mission submission fails with HTTP 403 | **P3 - Low** | Logged-in user has `viewer` role or belongs to different organization. | Request role upgrade to `operator` or check user organization assignment in Supabase. |

---

## 2. Standard Operating Procedures (SOP)

### SOP-01: Gateway Backend Unavailable
1. **Detect**: Health check monitor alerts on failed `http://<host>:8000/health/live`.
2. **Diagnose**:
   ```bash
   docker ps -a | grep agvnexus
   docker logs --tail 100 agvnexus-gateway
   ```
3. **Remediate**:
   ```bash
   docker restart agvnexus-gateway
   curl -f http://localhost:8000/health/ready
   ```
4. **Escalate**: If container fails repeatedly, check host memory exhaustion (`free -m`) and disk space (`df -h`).

### SOP-02: Robot Disconnected / Stale Telemetry
1. **Detect**: UI telemetry pill switches to Amber (`STALE`) or Red (`OFFLINE`).
2. **Immediate Safety Action**:
   - Software commands are automatically halted by the gateway during disconnect.
   - Onboard robot safety interlocks automatically engage mechanical brakes if safety heartbeats cease.
3. **Diagnose**:
   - Ping robot IP from gateway host: `ping 192.168.1.101`.
   - Inspect ROS 2 topic echoes: `ros2 topic echo /odom --once`.
4. **Recovery**: Once network link recovers, verify telemetry transitions to green (`LIVE`) before resuming autonomous transport orders.

### SOP-03: 3D WebGL Digital Twin Initialization Failure
1. **Detect**: User sees error message "WebGL initialization failed" or black viewport.
2. **Fallback**:
   - The UI automatically displays the "2D Failsafe Fallback" toggle button.
   - Clicking toggle activates the Flutter native `IsometricViewportPainter`.
   - All robot poses, station coordinates, and battery indicators continue updating accurately without WebGL.
3. **Resolution**: Refresh browser with GPU acceleration enabled (`chrome://settings/system`).

### SOP-04: Mission Dispatch Errors & Replay Prevention
1. **Detect**: Mission button displays dispatch error or timeout.
2. **Do Not Blindly Retry**: Every mission dispatch carries an internal `idempotency_key`. The gateway prevents duplicate missions.
3. **Verification**:
   - Navigate to `/missions` or inspect robot status to see if mission ID was created.
   - If mission status is `queued` or `assigned`, wait for robot acknowledgment.
   - If error persists, inspect `/api/v1/robots/{id}/status` for active obstacle interlocks.

---

## 3. Safe Recovery & Emergency Escalation

> [!CAUTION]
> **Emergency Escalation Rule**:
> If an AGV deviates from its path, ignores stop commands, or presents an immediate collision hazard:
> 1. Immediately press the physical Red E-Stop push button on the robot chassis.
> 2. Disconnect physical battery isolator switch if safe to do so.
> 3. Clear personnel from the transit corridor.
> 4. Notify Plant Safety Lead and Robotics Engineering On-Call.
