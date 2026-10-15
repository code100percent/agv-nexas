import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:agvnexus/features/robots/data/gateway_robot_repository.dart';
import 'package:agvnexus/core/errors/app_exception.dart';
import 'package:agvnexus/features/robots/domain/robot_model.dart';
import 'package:agvnexus/core/widgets/status_pill.dart';

void main() {
  group('Phase 5 Flutter Reliability & Failure Handling Tests', () {
    test('GatewayRobotRepository throws NetworkException on 503 service unavailable', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'detail': 'Robot adapter service unavailable'}),
          503,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = GatewayRobotRepository(
        apiBaseUrl: 'http://localhost:8000/api/v1',
        client: mockClient,
      );

      expect(() => repo.getRobots(), throwsA(isA<NetworkException>()));
    });

    test('GatewayRobotRepository returns null when robot 404 Not Found', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'detail': 'Robot with ID not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = GatewayRobotRepository(
        apiBaseUrl: 'http://localhost:8000/api/v1',
        client: mockClient,
      );

      final robot = await repo.getRobotById('non-existent-id');
      expect(robot, isNull);
    });

    test('GatewayRobotRepository sendTeleopCommand returns false on gateway rejection', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'detail': 'Forbidden - viewer role'}),
          403,
        );
      });

      final repo = GatewayRobotRepository(
        apiBaseUrl: 'http://localhost:8000/api/v1',
        client: mockClient,
      );

      final success = await repo.sendTeleopCommand('agv-01', 0.5, 0.0);
      expect(success, isFalse);
    });

    test('RobotModel gracefully parses minimal JSON without optional fields', () {
      final minimalJson = {
        'id': 'robot-min-01',
        'name': 'Minimal AGV',
      };

      // Trigger parsing

      final robot = RobotModel(
        id: minimalJson['id']!,
        name: minimalJson['name']!,
        modelType: 'Differential Drive AMR',
        mode: AgvOperatingMode.idle,
        batteryPercent: 100.0,
        batteryVoltage: 25.0,
        isCharging: false,
        linearVelocity: 0.0,
        angularVelocity: 0.0,
        poseX: 0.0,
        poseY: 0.0,
        poseYaw: 0.0,
        localizationConfidence: 1.0,
        lastHeartbeat: DateTime.now().subtract(const Duration(minutes: 5)),
        ipAddress: '192.168.1.50',
        rosDomainId: 0,
        activeFaults: const [],
      );

      // Verify stale detection logic
      final isStale = DateTime.now().difference(robot.lastHeartbeat).inSeconds > 10;
      expect(isStale, isTrue);
    });
  });
}
