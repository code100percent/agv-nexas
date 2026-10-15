# AGV Nexus: Teammate Laptop Setup, Physical AGV Audit & Connectivity Guide
**Phase 7 Handover & Comprehensive Operational Runbook**

---

## 1. Executive Summary & Architecture Overview

The **AGV Nexus** platform is an industrial robotics fleet management and digital twin control center designed for differential-drive Autonomous Mobile Robots (AMRs).

### System Topology
```
┌─────────────────────────────────────────────────────────────┐
│                 AGV Nexus Command Center                    │
│   (Flutter Web/Desktop UI on Port 3000 / Chrome / Native)   │
└───────────────────────────▲─────────────────────────────────┘
                            │ REST / WebSocket (10 Hz)
┌───────────────────────────▼─────────────────────────────────┐
│              FastAPI Robotics Gateway (/api/v1)             │
│            • WebSocket Manager (/ws/telemetry)              │
│            • 3D WebGL Digital Twin (/viewer)                │
│            • Supabase Auth & Multi-tenant RBAC              │
└───────────────────────────▲─────────────────────────────────┘
                            │ DDS / Topics (ROS 2 Humble/Jazzy)
┌───────────────────────────▼─────────────────────────────────┐
│               Teammate Robot Laptop / SBC                   │
│   • /wheel_ticks (Int32MultiArray) -> encoder_odometry.py   │
│   • /odom (nav_msgs/Odometry) + TF odom->base_footprint     │
│   • /scan (sensor_msgs/LaserScan from 2D LiDAR)             │
│   • /map (nav_msgs/OccupancyGrid from slam_toolbox)         │
│   • /cmd_vel (geometry_msgs/Twist) <- Teleop / Nav2         │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Stage 1: Teammate Computer & OS Audit

Before starting or modifying any software, perform this non-destructive audit on the teammate's laptop.

### 2.1 Operating System & Architecture Check
Run the following in the teammate's terminal:
```bash
# Check OS distribution and kernel
uname -a
cat /etc/os-release

# Check CPU architecture (x86_64 or aarch64)
lscpu | grep "Architecture\|Model name"

# Check available memory and storage space
free -h
df -h /
```
*Requirement:* Ubuntu 22.04 LTS (for ROS 2 Humble) or Ubuntu 24.04 LTS (for ROS 2 Jazzy) with at least 4 GB RAM and 10 GB free disk space.

### 2.2 Installed Tools Verification
```bash
# Check Git, Python, and build tools
git --version
python3 --version
colcon --help | head -n 2
cmake --version
```

### 2.3 ROS 2 Installation Check
```bash
# Verify if ROS 2 is installed in /opt/ros
ls -d /opt/ros/*

# Check if environment is already active
echo $ROS_DISTRO
echo $ROS_DOMAIN_ID
```
*Safe Practice:* If `ROS_DISTRO` is empty, activate it:
```bash
source /opt/ros/humble/setup.bash  # or /opt/ros/jazzy/setup.bash
```

---

## 3. Stage 2: Physical Robot Hardware Inventory

| Component | Hardware Specification | Expected Interface | Verification Command |
| :--- | :--- | :--- | :--- |
| **Chassis** | Differential Drive (2 drive wheels + casters) | Physical Track: 0.35m, Wheel Diameter: 0.10m | Physical tape measure check |
| **Motor Controller** | ESP32 / Arduino / STM32 via USB Serial | `/dev/ttyUSB0` or `/dev/ttyACM0` (115200 baud) | `ls -l /dev/ttyUSB* /dev/ttyACM*` |
| **Wheel Encoders** | Quadrature Optical/Magnetic Encoders | 900 ticks/revolution | Inspect tick count on manual wheel rotation |
| **2D Safety LiDAR** | RPLiDAR A1/A2/S1, LD19, or YDLidar (360° FOV) | USB to UART (`/dev/ttyUSB1`) | `lsusb` |
| **Power Source** | 24V LiFePO4 / Li-ion battery pack with BMS | Power switch & physical emergency stop button | Multimeter check (>24.0V) |

---

## 4. Stage 3: Step-by-Step Launch Procedure on Teammate Laptop

The teammate will run the robot software in separate terminals.

### Terminal 1: Build & Source Robot Workspace
```bash
# Navigate to the robot workspace
cd ~/Desktop/Agv\ Nexus/agv_robot/mobile_robot

# Build packages cleanly
colcon build --symlink-install

# Source overlay
source install/setup.bash
```

### Terminal 2: Start Motor Encoder Odometry Driver
```bash
source /opt/ros/humble/setup.bash
source ~/Desktop/Agv\ Nexus/agv_robot/mobile_robot/install/setup.bash

# Run encoder odometry node
ros2 launch mobile_robot_driver driver.launch.py
```
*Expected Output:*
```
[INFO] [encoder_odometry]: Listening on /wheel_ticks; publishing /odom and odom -> base_footprint
```

### Terminal 3: Start 2D LiDAR Driver
```bash
# Launch your robot's LiDAR node (e.g., sllidar / rplidar_ros)
ros2 launch sllidar_ros2 sllidar_a1_launch.py serial_port:=/dev/ttyUSB1
```

### Terminal 4: Start 2D Online Async SLAM (slam_toolbox)
```bash
source /opt/ros/humble/setup.bash
cd ~/Desktop/Agv\ Nexus/agv_robot/mobile_robot
ros2 launch slam_toolbox online_async_launch.py params_file:=./config/mapper_params_online_async.yaml
```
*Expected Output:*
```
[INFO] [slam_toolbox]: Registering sensor: [scan]
[INFO] [slam_toolbox]: Message filter successfully created
```

---

## 5. Stage 4: Read-Only Verification (Zero Motion Safety Gate)

Before allowing any motion or connecting the web dashboard, verify that data is streaming:

```bash
# 1. Verify active topics
ros2 topic list
# Must contain: /wheel_ticks, /odom, /scan, /map, /tf

# 2. Check wheel ticks publishing rate
ros2 topic hz /wheel_ticks

# 3. Check odometry output (gently rotate wheel by hand on a stand)
ros2 topic echo /odom --field pose.pose.position

# 4. Check LiDAR scan rate (should be ~10 Hz)
ros2 topic hz /scan
```

---

## 6. Stage 5: Network Connectivity Setup Between Both Laptops

### 6.1 Check IP Addresses
- **Teammate Robot Laptop:** Run `ip a` (e.g., `192.168.1.50`).
- **Your Workstation/App Laptop:** Run `ipconfig` (e.g., `192.168.1.100`).

### 6.2 Test Direct Ping
On your workstation:
```powershell
ping 192.168.1.50
```
On teammate laptop:
```bash
ping 192.168.1.100
```

### 6.3 Configure ROS 2 Discovery
Both computers must use the same Domain ID:
```bash
# On both machines
export ROS_DOMAIN_ID=0
```

---

## 7. Stage 6: Connecting AGV Nexus Backend to Physical Robot

On your workstation (or on the robot laptop if running self-contained):

1. Open `backend/.env` and update:
```ini
ROBOT_ADAPTER_MODE=ros2
ROS_DOMAIN_ID=0
ROS_NAMESPACE=
```

2. Start the FastAPI gateway:
```powershell
cd "c:\Users\hp\Desktop\Agv Nexus\backend"
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

3. Verify connection via browser:
   - Open `http://localhost:8000/health/ready`
   - Look for `"adapter_mode": "ros2"` and `"has_rclpy": true`.

4. Start Flutter command center:
```powershell
cd "c:\Users\hp\Desktop\Agv Nexus\agvnexus"
flutter run -d chrome
```

---

## 8. Stage 7: Safe Physical Motion Validation Protocol

Once read-only telemetry is verified in the 2D Map and 3D Digital Twin:

1. **Clear Safety Zone:** Ensure a 2-meter radius around the robot is clear of obstacles and personnel.
2. **Elevate Wheels (Bench Test):** Place the robot chassis on a wooden block so wheels spin freely in the air.
3. **Hardware Emergency Stop Test:** Keep a physical hand on the battery kill switch / emergency stop button.
4. **Minimal Teleop Pulse:**
   - In AGV Nexus UI, switch to the **Robots** tab.
   - Click the forward jog arrow once (linear velocity: $+0.10\text{ m/s}$).
   - Verify wheels turn forward smoothly.
   - Click the red **EMERGENCY STOP** button in the UI.
   - Verify wheels stop instantly (`/cmd_vel` receives `linear: 0, angular: 0`).
5. **Ground Test:** Lower robot to smooth floor and repeat at $0.05\text{ m/s}$.

---

## 9. Troubleshooting & Diagnostic Matrix

| Issue Observed | Root Cause | Solution |
| :--- | :--- | :--- |
| UI shows `SIMULATED` badge | `ROBOT_ADAPTER_MODE=simulated` in `backend/.env` | Change to `ROBOT_ADAPTER_MODE=ros2` and restart backend |
| Telemetry shows `STALE` | No `/odom` updates received for $>5.0$ seconds | Check if `encoder_odometry.py` is running on robot laptop |
| `/dev/ttyUSB0: Permission denied` | User not in Linux `dialout` group | Run `sudo usermod -aG dialout $USER`, then log out and log back in |
| Topics not visible across laptops | Firewall blocking UDP multicast / different Domain ID | Allow UDP ports in firewall: `sudo ufw allow 7400:7500/udp` and verify `echo $ROS_DOMAIN_ID` |
