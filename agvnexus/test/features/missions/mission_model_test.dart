import 'package:flutter_test/flutter_test.dart';
import 'package:agvnexus/features/missions/domain/mission_model.dart';

void main() {
  group('MissionModel State Tests', () {
    test('Correctly determines active missions', () {
      final inProgressMission = MissionModel(
        id: 'MSN-01',
        name: 'Transfer',
        sourceStationId: 'A',
        sourceStationName: 'Bay A',
        destinationStationId: 'B',
        destinationStationName: 'Bay B',
        status: MissionStatus.inProgress,
        priority: MissionPriority.high,
        progressPercent: 50.0,
        payloadWeightKg: 100.0,
        createdAt: DateTime.now(),
      );

      final completedMission = inProgressMission.copyWith(
        status: MissionStatus.completed,
        progressPercent: 100.0,
      );

      expect(inProgressMission.isActive, isTrue);
      expect(completedMission.isActive, isFalse);
    });
  });
}
