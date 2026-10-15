import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:agvnexus/features/robots/data/gateway_robot_repository.dart';

void main() {
  group('GatewayRobotRepository Tests (Phase 3)', () {
    test('getRobots parses valid list of robots from FastAPI', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/robots'));
        final responseData = [
          {
            'id': 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01',
            'name': 'Titan-01',
            'robot_code': 'AGV-01',
            'robot_type': 'differential_drive',
            'max_payload_kg': 15.0,
            'operating_mode': 'idle',
            'battery_percent': 95.0,
            'battery_voltage': 25.5,
          },
        ];
        return http.Response(
          json.encode(responseData),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final repo = GatewayRobotRepository(
        apiBaseUrl: 'http://localhost:8000/api/v1',
        client: mockClient,
      );

      final robots = await repo.getRobots();
      expect(robots.length, equals(1));
      expect(robots.first.id, equals('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01'));
      expect(robots.first.name, equals('Titan-01'));
      expect(robots.first.batteryPercent, equals(95.0));
    });

    test(
      'sendTeleopCommand dispatches POST with linear and angular velocities',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.url.path, equals('/api/v1/robots/agv-01/teleop'));
          final body = json.decode(request.body);
          expect(body['linear_velocity'], equals(0.35));
          expect(body['angular_velocity'], equals(0.50));
          return http.Response(json.encode({'status': 'command_sent'}), 200);
        });

        final repo = GatewayRobotRepository(
          apiBaseUrl: 'http://localhost:8000/api/v1',
          client: mockClient,
        );

        final success = await repo.sendTeleopCommand('agv-01', 0.35, 0.50);
        expect(success, isTrue);
      },
    );
  });
}
