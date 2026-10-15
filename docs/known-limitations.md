# AGV Nexus - Known Limitations & Assumptions Register (Phase 1)

This document tracks all design decisions, architectural boundaries, and known limitations of AGV Nexus during **Phase 1: Flutter Foundation and Premium UI**.

---

## 1. Simulated Telemetry (Phase 1 Boundary)
* **Status**: Intentional Phase 1 architecture.
* **Details**: AMR telemetry (odometry velocities, poses, LiDAR beam sweeps, and battery voltages) is currently simulated using deterministic periodic streams in `MockRobotRepository`.
* **Safety & Transparency**: No screen falsely presents mock data as live hardware telemetry; all headers display prominent `SIMULATED` badges. Live ROS 2 DDS integration is scheduled for Phase 3.

---

## 2. Mock Directory Authentication
* **Status**: Temporary mock repository.
* **Details**: Sign-in is verified against predefined demo personas in `MockAuthRepository`.
* **Resolution**: Phase 2 will introduce Supabase Auth with PostgreSQL Row-Level Security (RLS) policies and session token storage via `flutter_secure_storage`.

---

## 3. Industrial Safety Responsibility
* **Status**: Non-negotiable safety invariant (ISO 3691-4).
* **Details**: Software emergency stop buttons in the UI are convenience commands only. Physical personnel safety and collision protection depend strictly on local, hardwired, certified safety relays and collision bumpers on the physical AGV.

---

## 4. 2D Occupancy Grid Resolution
* **Status**: Functional simulated raster.
* **Details**: The 2D map renderer uses Flutter's `CustomPainter` to draw a 20m x 15m grid with simulated obstacles, charging bays, and waypoints. Real PGM/YAML map parsing and dynamic costmap updates will be connected via the FastAPI gateway in Phase 3.
