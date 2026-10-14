from launch import LaunchDescription
from launch_ros.actions import Node


def generate_launch_description():
	return LaunchDescription([
		Node(
			package='mobile_robot_driver',
			executable='encoder_odometry',
			name='encoder_odometry',
			output='screen',
		),
	])