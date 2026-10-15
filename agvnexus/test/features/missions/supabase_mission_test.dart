import 'package:flutter_test/flutter_test.dart';
import 'package:agvnexus/features/missions/domain/mission_model.dart';

void main() {
  group('Supabase MissionModel Mapping & Lifecycle Tests (Phase 2)', () {
    test('Parses database mission with joined station and robot records', () {
      final dbRow = {
        'id': 'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380e01',
        'organization_id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'robot_id': 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01',
        'pickup_station_id': 'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380d01',
        'dropoff_station_id': 'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380d02',
        'status': 'in_progress',
        'priority': 3,
        'payload_kg': 14.5,
        'created_at': '2026-03-01T10:00:00.000Z',
        'started_at': '2026-03-01T10:05:00.000Z',
        'robots': {'name': 'Titan-01'},
        'pickup_station': {'name': 'Warehouse Bay A'},
        'dropoff_station': {'name': 'Assembly Line 4'},
      };

      final mission = MissionModel.fromSupabase(dbRow);

      expect(mission.id, 'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380e01');
      expect(mission.assignedRobotName, 'Titan-01');
      expect(mission.sourceStationName, 'Warehouse Bay A');
      expect(mission.destinationStationName, 'Assembly Line 4');
      expect(mission.status, MissionStatus.inProgress);
      expect(mission.priority, MissionPriority.high);
      expect(mission.isActive, isTrue);
      expect(mission.payloadWeightKg, 14.5);
    });

    test('Correctly maps queued and completed statuses', () {
      final queuedRow = {
        'id': 'msn-queued',
        'status': 'queued',
        'priority': 2,
        'pickup_station_id': 'bay-1',
        'dropoff_station_id': 'bay-2',
      };
      final queuedMission = MissionModel.fromSupabase(queuedRow);
      expect(queuedMission.status, MissionStatus.queued);
      expect(queuedMission.isActive, isTrue);

      final completedRow = {
        'id': 'msn-completed',
        'status': 'completed',
        'priority': 1,
        'pickup_station_id': 'bay-1',
        'dropoff_station_id': 'bay-2',
      };
      final completedMission = MissionModel.fromSupabase(completedRow);
      expect(completedMission.status, MissionStatus.completed);
      expect(completedMission.isActive, isFalse);
      expect(completedMission.progressPercent, 100.0);
    });
  });
}
