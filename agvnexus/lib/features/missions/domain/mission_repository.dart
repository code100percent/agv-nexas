import 'mission_model.dart';

abstract class MissionRepository {
  Future<List<MissionModel>> getMissions();
  Stream<List<MissionModel>> watchMissions();
  Future<MissionModel> createMission({
    required String name,
    required String sourceStationId,
    required String sourceStationName,
    required String destinationStationId,
    required String destinationStationName,
    required MissionPriority priority,
    required double payloadWeightKg,
    String? assignedRobotId,
  });
  Future<void> cancelMission(String missionId);
}
