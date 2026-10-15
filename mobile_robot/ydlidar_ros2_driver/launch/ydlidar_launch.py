#!/usr/bin/python3
# Updated for ROS 2 Jazzy. Starts the driver, the static transform and RViz2.

import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.conditions import IfCondition
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    share_dir = get_package_share_directory('ydlidar_ros2_driver')
    parameter_file = LaunchConfiguration('params_file')
    show_rviz = LaunchConfiguration('show_rviz')
    rviz_config = os.path.join(share_dir, 'config', 'ydlidar.rviz')

    params_declare = DeclareLaunchArgument(
        'params_file',
        default_value=os.path.join(share_dir, 'params', 'ydlidar.yaml'),
        description='Path to the ROS 2 parameters file to use.')
    show_rviz_declare = DeclareLaunchArgument(
        'show_rviz',
        default_value='false',
        description='Launch RViz if true.')

    driver_node = Node(
        package='ydlidar_ros2_driver',
        executable='ydlidar_ros2_driver_node',
        name='ydlidar_ros2_driver_node',
        output='screen',
        emulate_tty=True,
        parameters=[parameter_file],
        namespace='/',
    )

    tf2_node = Node(
        package='tf2_ros',
        executable='static_transform_publisher',
        name='static_tf_pub_laser',
        arguments=['--x', '0', '--y', '0', '--z', '0.02',
                   '--qx', '0', '--qy', '0', '--qz', '0', '--qw', '1',
                   '--frame-id', 'base_link',
                   '--child-frame-id', 'laser_frame'],
    )

    # Use the package's RViz config if it exists, otherwise start RViz empty
    rviz_args = ['-d', rviz_config] if os.path.exists(rviz_config) else []
    rviz_node = Node(
        package='rviz2',
        executable='rviz2',
        name='rviz2',
        arguments=rviz_args,
        condition=IfCondition(show_rviz),
    )

    return LaunchDescription([
        params_declare,
        show_rviz_declare,
        driver_node,
        tf2_node,
        rviz_node,
    ])