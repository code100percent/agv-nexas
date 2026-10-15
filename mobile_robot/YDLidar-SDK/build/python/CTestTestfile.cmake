# CMake generated Testfile for 
# Source directory: /home/sehaj/dev/ros_learning/autonomous-ground-vechile-for-factory/src/mobile_robot/YDLidar-SDK/python
# Build directory: /home/sehaj/dev/ros_learning/autonomous-ground-vechile-for-factory/src/mobile_robot/YDLidar-SDK/build/python
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(ydlidar_py_test "/usr/bin/python" "/home/sehaj/dev/ros_learning/autonomous-ground-vechile-for-factory/src/mobile_robot/YDLidar-SDK/python/test/pytest.py")
set_tests_properties(ydlidar_py_test PROPERTIES  ENVIRONMENT "PYTHONPATH=/home/sehaj/ros2_ws/install/algorithms/lib/python3.12/site-packages:/opt/ros/jazzy/opt/gz_sim_vendor/lib/python:/opt/ros/jazzy/opt/sdformat_vendor/lib/python:/opt/ros/jazzy/opt/gz_transport_vendor/lib/python:/opt/ros/jazzy/opt/gz_msgs_vendor/lib/python:/opt/ros/jazzy/opt/gz_math_vendor/lib/python:/opt/ros/jazzy/lib/python3.12/site-packages:/home/sehaj/dev/ros_learning/autonomous-ground-vechile-for-factory/src/mobile_robot/YDLidar-SDK/build/python" _BACKTRACE_TRIPLES "/home/sehaj/dev/ros_learning/autonomous-ground-vechile-for-factory/src/mobile_robot/YDLidar-SDK/python/CMakeLists.txt;42;add_test;/home/sehaj/dev/ros_learning/autonomous-ground-vechile-for-factory/src/mobile_robot/YDLidar-SDK/python/CMakeLists.txt;0;")
subdirs("examples")
