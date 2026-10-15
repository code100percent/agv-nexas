"""
Coordinate Transformations Module for AGV Nexus Digital Twin.

Converts between:
1. ROS 2 Navigation & Odometry Frame (REP-103: Right-handed, +X Forward, +Y Left, +Z Up)
2. Three.js WebGL Scene World Frame (Right-handed, +X Right, +Y Up, +Z Back towards Camera)
3. Planar Quaternion and Euler Heading representations
"""

import math
from typing import Optional, Tuple


def ros2_to_threejs_position(
    x: float, y: float, z: float = 0.0
) -> Tuple[float, float, float]:
    """
    Transform ROS 2 continuous world coordinates (meters) to Three.js world coordinates.
    ROS 2: +X Forward, +Y Left, +Z Up.
    Three.js: +X Right, +Y Up, -Z Forward (Camera looking down -Z).
    Therefore:
      Three.js X = x_ros
      Three.js Y = z_ros
      Three.js Z = -y_ros
    """
    three_x = float(x)
    three_y = float(z)
    three_z = float(-y)
    return three_x, three_y, three_z


def threejs_to_ros2_position(
    x: float, y: float, z: float
) -> Tuple[float, float, float]:
    """
    Inverse transform from Three.js scene coordinates back to ROS 2 REP-103 coordinates.
      ROS 2 x = Three.js X
      ROS 2 y = -Three.js Z
      ROS 2 z = Three.js Y
    """
    ros_x = float(x)
    ros_y = float(-z)
    ros_z = float(y)
    return ros_x, ros_y, ros_z


def ros2_yaw_to_threejs_rotation(yaw_radians: float) -> float:
    """
    Transform ROS 2 planar yaw heading (radians, counter-clockwise about +Z)
    to Three.js Y-axis rotation (radians).
    """
    # Normalize to [-pi, pi]
    norm_yaw = math.atan2(math.sin(yaw_radians), math.cos(yaw_radians))
    return norm_yaw


def yaw_to_quaternion(yaw_radians: float) -> Tuple[float, float, float, float]:
    """
    Convert planar yaw angle (radians) to normalized quaternion (qx, qy, qz, qw).
    For rotation purely around the Z axis in REP-103:
      qx = 0.0
      qy = 0.0
      qz = sin(theta / 2)
      qw = cos(theta / 2)
    """
    half_angle = yaw_radians / 2.0
    qx = 0.0
    qy = 0.0
    qz = math.sin(half_angle)
    qw = math.cos(half_angle)
    return qx, qy, qz, qw


def quaternion_to_yaw(qx: float, qy: float, qz: float, qw: float) -> float:
    """
    Extract planar yaw angle (radians) from quaternion (qx, qy, qz, qw).
    yaw = atan2(2*(qw*qz + qx*qy), 1 - 2*(qy^2 + qz^2))
    """
    siny_cosp = 2.0 * (qw * qz + qx * qy)
    cosy_cosp = 1.0 - 2.0 * (qy * qy + qz * qz)
    yaw = math.atan2(siny_cosp, cosy_cosp)
    return math.atan2(math.sin(yaw), math.cos(yaw))


def validate_pose_coordinates(
    x: Optional[float],
    y: Optional[float],
    z: Optional[float] = 0.0,
    yaw: Optional[float] = 0.0,
) -> bool:
    """
    Validate that numerical coordinates are finite, non-null, and within operational limits.
    Rejects NaN, +/-Inf, and extreme out-of-bounds anomalies (> 1000m).
    """
    if x is None or y is None:
        return False
    for val in (x, y, z or 0.0, yaw or 0.0):
        if math.isnan(val) or math.isinf(val):
            return False
    # Bounds check for factory premises (within +/- 500 meters)
    if abs(x) > 500.0 or abs(y) > 500.0:
        return False
    return True
