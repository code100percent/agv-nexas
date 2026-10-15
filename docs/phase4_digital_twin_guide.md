# AGV Nexus - Phase 4: 3D Digital Twin, Spatial Visualization & Intelligent Mission Visualization Guide

## 1. Overview
AGV Nexus Phase 4 introduces a state-of-the-art interactive 3D Digital Twin viewer powered by Three.js WebGL, synchronized via authenticated WebSockets with the Phase 3 FastAPI Robotics Gateway and ROS 2/Gazebo simulations.

---

## 2. Coordinate System Specifications

### 2.1 Coordinate Conventions
1. **ROS 2 Navigation & Odometry (REP-103)**:
   - $+X$: Forward / East
   - $+Y$: Left / North
   - $+Z$: Up
   - Angles: Radians, counter-clockwise rotation about $+Z$ (Yaw $\theta$)
2. **Three.js WebGL Coordinate Space**:
   - $+X$: Rightwards
   - $+Y$: Upwards
   - $+Z$: Backwards (Towards viewer camera)
   - Standard Camera: Looking along $-Z$ towards the floor
3. **Discrete Metric Occupancy Grid**:
   - $Width \times Height$ cells
   - Cell $(col, row)$ center:
     $$x_{\text{world}} = (col + 0.5) \times \text{resolution} + origin.x$$
     $$y_{\text{world}} = (row + 0.5) \times \text{resolution} + origin.y$$

### 2.2 Mathematical Transform to WebGL Scene
To preserve right-handed physics and ensure ROS 2 forward $(+X)$ maps to Three.js world axes:
$$X_{\text{three}} = x_{\text{ros}}$$
$$Y_{\text{three}} = z_{\text{ros}}$$
$$Z_{\text{three}} = -y_{\text{ros}}$$
$$\text{rotation.y} = \theta_{\text{ros}}$$

---

## 3. Physical Robot Dimensions & Mesh Specs
Derived from `agv_robot/mobile_robot/robot_description/urdf/mobile_robot.urdf`:
- **Chassis Base Plate**: $0.395\text{ m} \times 0.279\text{ m} \times 0.015\text{ m}$ at $Z = 0.05\text{ m}$ (above ground).
- **Drive Wheels**: Differential drive, Diameter $0.10\text{ m}$, Width $0.04\text{ m}$, Track Width $0.35\text{ m}$.
- **Support Rods**: 4 vertical threaded rods of length $0.08\text{ m}$.
- **Middle Shelf**: $0.395\text{ m} \times 0.279\text{ m}$ at $Z = 0.145\text{ m}$.
- **Upper Extrusions**: 4 vertical aluminium rods of length $0.36\text{ m}$.
- **Top Deck**: $0.330\text{ m} \times 0.228\text{ m}$ at $Z = 0.5075\text{ m}$.
- **Planar 2D LiDAR**: Cylinder radius $0.035\text{ m}$, length $0.040\text{ m}$ at $Z \approx 0.54\text{ m}$.

---

## 4. Factory Arena Layout
Derived from `agv_robot/mobile_robot/config/factory_arenas2.sdf`:
- **Floor**: $38.0\text{ m} \times 24.0\text{ m}$ metric floor plane with 1m/5m industrial grid.
- **Enclosing Walls**: $38.5\text{ m} \times 24.0\text{ m} \times 5.0\text{ m}$ height.
- **Heavy Pallet Racks**: Upright steel rack pillars at $(15.87, -4.20)$ and $(9.47, -4.20)$.
- **Warehouse Stations**:
  - `Warehouse Bay A`: $(2.5, 3.0)$
  - `Assembly Line 4`: $(14.2, 8.5)$
  - `Charging Dock 01`: $(1.2, 1.0)$
  - `Quality Inspection 2`: $(8.0, 12.0)$

---

## 5. WebGL Viewer Architecture (`viewer/`)
- `viewer/index.html`: Responsive HTML5 canvas, camera presets, HUD readouts, layer toggles.
- `viewer/css/viewer.css`: Industrial dark theme (#0A0E17, #111827, #1E293B, #00F0FF cyan, #10B981 emerald).
- `viewer/js/transforms.js`: High-precision coordinate frame converter.
- `viewer/js/scene.js`: WebGLRenderer, shadow maps, lighting, context recovery.
- `viewer/js/camera.js`: OrbitControls, Isometric, Top-Down, Follow, Free Orbit.
- `viewer/js/environment.js`: Factory arena structures, ground plane, walls, racks.
- `viewer/js/occupancy.js`: 2D occupancy grid layer.
- `viewer/js/robot.js`: Procedural AGV matching URDF dimensions + GLB loader support.
- `viewer/js/lidar.js`: 2D planar LaserScan visualization fan rays.
- `viewer/js/stations.js`: Interactive 3D stations with beacons and selection.
- `viewer/js/missions.js`: Multi-segment route splines with progress highlighting.
- `viewer/js/telemetry.js`: Authenticated WebSocket streaming with bounded interpolation.
- `viewer/js/app.js`: Master controller and postMessage bridge.

---

## 6. Verification and Guardrails
1. **Planar LiDAR Honesty**: The sensor is a 2D planar LiDAR scanner, not a dense 3D point cloud scanner. Visualizations represent 2D range fans in 3D space.
2. **Operational Safety**: 3D clicks never trigger motor movements without authenticated confirmation.
3. **2D Failsafe**: Flutter CustomPainter fallback is permanently available when WebGL is uninitialized or unsupported.
