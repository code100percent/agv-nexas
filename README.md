# AUTONOMOUS GROUND Vechile for autonomous factory logistics

This directory contains the ROS 2 source packages for a differential-drive
mobile robot. The packages provide encoder-based odometry, the robot model,
and YDLIDAR support, along with a SLAM Toolbox parameter file.

## Packages

| Package or directory | Purpose |
| --- | --- |
| `mobile_robot/mobile_robot_driver` | Computes odometry and publishes the `odom` to `base_footprint` transform from wheel encoder ticks. |
| `mobile_robot/robot_description` | Robot URDF, display launch file, and RViz configuration. |
| `mobile_robot/ydlidar_ros2_driver` | YDLIDAR ROS 2 driver, launch files, device parameters, and RViz configuration. |
| `mobile_robot/config` | SLAM Toolbox online-async parameters. |

## Requirements

- ROS 2 Jazzy
- `colcon` and `rosdep`
- A supported YDLIDAR connected to the robot (for hardware runs)

Install package dependencies from the workspace root:

```bash
rosdep install --from-paths src --ignore-src -r -y
```

## Build

From the workspace root:

```bash
colcon build --symlink-install
source install/setup.bash
```

## Launch

Run each command in a separate terminal after sourcing the workspace:

```bash
# Encoder odometry; expects left and right cumulative counts on /wheel_ticks.
ros2 launch mobile_robot_driver driver.launch.py

# Robot model and joint-state GUI; add show_rviz:=true to open RViz.
ros2 launch robot_description display.launch.py show_rviz:=true

# YDLIDAR and its base-to-laser transform; add show_rviz:=true to open RViz.
ros2 launch ydlidar_ros2_driver ydlidar_launch.py show_rviz:=true
```

The default YDLIDAR settings use `/dev/ttyUSB0`; update
`mobile_robot/ydlidar_ros2_driver/params/ydlidar.yaml` if your device uses a
different serial port or configuration.

## Mapping configuration

`mobile_robot/config/mapper_params_online_async.yaml` contains the SLAM Toolbox
frame, scan, and map settings. Before using it, check that its frame names and
map file path match your robot and machine. The current map path is specific to
the original development environment.
