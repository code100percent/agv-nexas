import 'package:flutter_test/flutter_test.dart';
import 'package:agvnexus/features/robots/domain/robot_model.dart';
import 'package:agvnexus/core/widgets/status_pill.dart';

void main() {
  group('RobotModel Telemetry & Connectivity Tests', () {
    test('Identifies fresh heartbeat as connected', () {
      final robot = RobotModel(
        id: 'agv-01',
        name: 'Titan-01',
        modelType: 'Diff-Drive 500kg',
        mode: AgvOperatingMode.navigating,
        batteryPercent: 88.0,
        batteryVoltage: 25.4,
        isCharging: false,
        linearVelocity: 0.5,
        angularVelocity: 0.0,
        poseX: 10.0,
        poseY: 5.0,
        poseYaw: 0.0,
        localizationConfidence: 0.95,
        lastHeartbeat: DateTime.now(),
        ipAddress: '192.168.1.101',
        rosDomainId: 42,
      );

      expect(robot.isConnected, isTrue);
      expect(robot.hasFaults, isFalse);
    });

    test('Stale heartbeat over 10s is marked as disconnected', () {
      final robot = RobotModel(
        id: 'agv-02',
        name: 'Atlas-02',
        modelType: 'Diff-Drive 500kg',
        mode: AgvOperatingMode.offline,
        batteryPercent: 50.0,
        batteryVoltage: 24.0,
        isCharging: false,
        linearVelocity: 0.0,
        angularVelocity: 0.0,
        poseX: 2.0,
        poseY: 2.0,
        poseYaw: 0.0,
        localizationConfidence: 0.0,
        lastHeartbeat: DateTime.now().subtract(const Duration(seconds: 15)),
        ipAddress: '192.168.1.102',
        rosDomainId: 42,
      );

      expect(robot.isConnected, isFalse);
    });

    test('Active faults are properly recognized', () {
      final robot = RobotModel(
        id: 'agv-04',
        name: 'Hermes-04',
        modelType: 'Tug 1000kg',
        mode: AgvOperatingMode.fault,
        batteryPercent: 40.0,
        batteryVoltage: 23.5,
        isCharging: false,
        linearVelocity: 0.0,
        angularVelocity: 0.0,
        poseX: 18.0,
        poseY: 4.0,
        poseYaw: 0.0,
        localizationConfidence: 0.8,
        lastHeartbeat: DateTime.now(),
        ipAddress: '192.168.1.104',
        rosDomainId: 42,
        activeFaults: ['E-204: LiDAR window obstructed'],
      );

      expect(robot.hasFaults, isTrue);
      expect(robot.activeFaults.length, 1);
    });
  });
}
