import 'package:flutter_test/flutter_test.dart';
import 'package:agvnexus/features/telemetry/domain/telemetry_model.dart';

void main() {
  group('TelemetryModel Tests (Phase 3)', () {
    test('Parses complete JSON snapshot from FastAPI WebSocket/REST', () {
      final json = {
        'robot_id': 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01',
        'timestamp': '2026-10-15T12:00:00.000Z',
        'source': 'simulated',
        'connection_state': 'connected',
        'data_freshness': 'fresh',
        'position_x': 3.14,
        'position_y': 2.71,
        'position_z': 0.0,
        'yaw': 1.57,
        'linear_velocity': 0.35,
        'angular_velocity': 0.05,
        'left_wheel_ticks': 152000,
        'right_wheel_ticks': 152000,
        'battery_percentage': 92.5,
        'battery_voltage': 25.1,
        'is_charging': false,
        'robot_operating_state': 'navigating',
        'localization_confidence': 0.98,
        'active_mission_id': 'mission-101',
        'active_faults': <String>[],
      };

      final telem = TelemetryModel.fromJson(json);

      expect(telem.robotId, equals('b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01'));
      expect(telem.positionX, equals(3.14));
      expect(telem.positionY, equals(2.71));
      expect(telem.linearVelocity, equals(0.35));
      expect(telem.leftWheelTicks, equals(152000));
      expect(telem.batteryPercent, equals(92.5));
      expect(telem.isConnected, isTrue);
      expect(telem.isFresh, isTrue);
      expect(telem.isSimulated, isTrue);
    });

    test('Handles null and missing fields gracefully without crash', () {
      final json = {
        'robot_id': 'agv-01',
        'source': 'disconnected',
        'connection_state': 'disconnected',
        'data_freshness': 'stale',
      };

      final telem = TelemetryModel.fromJson(json);

      expect(telem.robotId, equals('agv-01'));
      expect(telem.positionX, isNull);
      expect(telem.batteryPercent, isNull);
      expect(telem.isConnected, isFalse);
      expect(telem.isFresh, isFalse);
      expect(telem.operatingState, equals('idle'));
      expect(telem.activeFaults, isEmpty);
    });
  });
}
