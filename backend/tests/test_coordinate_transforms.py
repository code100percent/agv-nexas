import math
import pytest
from app.core.coordinate_transforms import (
    quaternion_to_yaw,
    ros2_to_threejs_position,
    ros2_yaw_to_threejs_rotation,
    threejs_to_ros2_position,
    validate_pose_coordinates,
    yaw_to_quaternion,
)


def test_ros2_to_threejs_position_mapping():
    # ROS 2: +X Forward (10m), +Y Left (5m), +Z Up (0.5m)
    x, y, z = ros2_to_threejs_position(10.0, 5.0, 0.5)
    # Three.js: X = x_ros, Y = z_ros, Z = -y_ros
    assert x == 10.0
    assert y == 0.5
    assert z == -5.0


def test_roundtrip_coordinate_conversion():
    orig_x, orig_y, orig_z = 14.2, 8.5, 0.05
    three_x, three_y, three_z = ros2_to_threejs_position(orig_x, orig_y, orig_z)
    back_x, back_y, back_z = threejs_to_ros2_position(three_x, three_y, three_z)

    assert math.isclose(orig_x, back_x, abs_tol=1e-6)
    assert math.isclose(orig_y, back_y, abs_tol=1e-6)
    assert math.isclose(orig_z, back_z, abs_tol=1e-6)


def test_yaw_to_quaternion_cardinal_directions():
    # 0 radians (facing East/+X)
    qx, qy, qz, qw = yaw_to_quaternion(0.0)
    assert qx == 0.0
    assert qy == 0.0
    assert qz == 0.0
    assert qw == 1.0
    assert math.isclose(quaternion_to_yaw(qx, qy, qz, qw), 0.0, abs_tol=1e-6)

    # pi/2 radians (90 deg, facing North/+Y)
    qx, qy, qz, qw = yaw_to_quaternion(math.pi / 2)
    assert math.isclose(qz, math.sin(math.pi / 4), abs_tol=1e-6)
    assert math.isclose(qw, math.cos(math.pi / 4), abs_tol=1e-6)
    assert math.isclose(quaternion_to_yaw(qx, qy, qz, qw), math.pi / 2, abs_tol=1e-6)

    # pi radians (180 deg, facing West/-X)
    qx, qy, qz, qw = yaw_to_quaternion(math.pi)
    assert math.isclose(qz, 1.0, abs_tol=1e-6)
    assert math.isclose(qw, 0.0, abs_tol=1e-6)
    assert math.isclose(abs(quaternion_to_yaw(qx, qy, qz, qw)), math.pi, abs_tol=1e-6)


def test_yaw_rotation_normalization():
    # Wrap-around angles: 3*pi should normalize to -pi or pi
    three_yaw = ros2_yaw_to_threejs_rotation(3 * math.pi)
    assert math.isclose(abs(three_yaw), math.pi, abs_tol=1e-6)

    # Negative wrap around: -3*pi/2 should normalize to pi/2
    three_yaw_neg = ros2_yaw_to_threejs_rotation(-3 * math.pi / 2)
    assert math.isclose(three_yaw_neg, math.pi / 2, abs_tol=1e-6)


def test_validate_pose_coordinates():
    # Valid pose
    assert validate_pose_coordinates(2.5, 3.0, 0.0, 0.5) is True

    # Missing essential coordinate
    assert validate_pose_coordinates(None, 3.0) is False
    assert validate_pose_coordinates(2.5, None) is False

    # NaN / Inf rejection
    assert validate_pose_coordinates(float("nan"), 3.0) is False
    assert validate_pose_coordinates(2.5, float("inf")) is False

    # Extreme out-of-bounds anomaly (> 500m)
    assert validate_pose_coordinates(1500.0, 3.0) is False
    assert validate_pose_coordinates(2.5, -999.0) is False
