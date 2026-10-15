import 'robot_model.dart';

/// Abstract contract for robot fleet monitoring and commands.
abstract class RobotRepository {
  Future<List<RobotModel>> getRobots();
  Stream<List<RobotModel>> watchRobots();
  Future<RobotModel?> getRobotById(String id);
  Future<void> triggerEmergencyStop(String id);
  Future<void> clearFaults(String id);
}
