import 'package:flutter_test/flutter_test.dart';
import 'package:agvnexus/features/robots/domain/robot_model.dart';
import 'package:agvnexus/core/widgets/status_pill.dart';

void main() {
  group('Supabase RobotModel Mapping & Connectivity Tests (Phase 2)', () {
    test('Parses database robot row with correct metadata', () {
      final dbRow = {
        'id': 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01',
        'organization_id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'name': 'Titan-01',
        'robot_code': 'AGV-01',
        'description': 'Heavy-duty pallet mover',
        'robot_type': 'differential_drive',
        'max_payload_kg': 15.0,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      };

      final robot = RobotModel.fromSupabase(dbRow);

      expect(robot.id, 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01');
      expect(robot.name, 'Titan-01');
      expect(robot.modelType, 'differential_drive');
      expect(robot.mode, AgvOperatingMode.idle);
      expect(robot.isConnected, isTrue);
      expect(robot.hasFaults, isFalse);
    });

    test('Identifies stale last_seen_at as disconnected', () {
      final staleRow = {
        'id': 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b02',
        'name': 'Atlas-02',
        'robot_code': 'AGV-02',
        'robot_type': 'differential_drive',
        'last_seen_at': DateTime.now()
            .subtract(const Duration(minutes: 15))
            .toUtc()
            .toIso8601String(),
      };

      final robot = RobotModel.fromSupabase(staleRow);

      expect(robot.isConnected, isFalse);
    });

    test('Serializes toMap and copies state with copyWith', () {
      final robot = RobotModel.fromSupabase({
        'id': 'agv-01',
        'name': 'Titan-01',
        'robot_code': '01',
      });

      final updated = robot.copyWith(batteryPercent: 42.5, isCharging: true);
      expect(updated.batteryPercent, 42.5);
      expect(updated.isCharging, isTrue);

      final map = updated.toMap();
      expect(map['id'], 'agv-01');
      expect(map['batteryPercent'], 42.5);
    });
  });
}
