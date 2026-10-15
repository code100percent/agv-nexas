import 'dart:async';
import '../domain/mission_model.dart';
import '../domain/mission_repository.dart';

/// Phase 1 Deterministic Mock Mission Repository.
class MockMissionRepository implements MissionRepository {
  List<MissionModel> _missions = [
    MissionModel(
      id: 'MSN-1042',
      name: 'Battery Pack Transfer to Line 3',
      assignedRobotId: 'agv-01',
      assignedRobotName: 'Titan-01',
      sourceStationId: 'STN-WH-A',
      sourceStationName: 'Warehouse Bay A',
      destinationStationId: 'STN-ASSY-3',
      destinationStationName: 'Assembly Line 3',
      status: MissionStatus.inProgress,
      priority: MissionPriority.high,
      progressPercent: 68.0,
      payloadWeightKg: 320.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      startedAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    MissionModel(
      id: 'MSN-1043',
      name: 'Motor Stator Transport',
      assignedRobotId: null,
      assignedRobotName: null,
      sourceStationId: 'STN-WH-B',
      sourceStationName: 'Storage Bay B2',
      destinationStationId: 'STN-CELL-1',
      destinationStationName: 'Robotic Cell 1',
      status: MissionStatus.queued,
      priority: MissionPriority.high,
      progressPercent: 0.0,
      payloadWeightKg: 180.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    MissionModel(
      id: 'MSN-1044',
      name: 'Empty Pallet Return',
      assignedRobotId: null,
      assignedRobotName: null,
      sourceStationId: 'STN-ASSY-2',
      sourceStationName: 'Assembly Line 2',
      destinationStationId: 'STN-PALLET',
      destinationStationName: 'Pallet Buffer Area',
      status: MissionStatus.queued,
      priority: MissionPriority.normal,
      progressPercent: 0.0,
      payloadWeightKg: 45.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    MissionModel(
      id: 'MSN-1041',
      name: 'Wiring Harness Dispatch',
      assignedRobotId: 'agv-03',
      assignedRobotName: 'Vanguard-03',
      sourceStationId: 'STN-ELEC',
      sourceStationName: 'Electronics Kitting',
      destinationStationId: 'STN-ASSY-4',
      destinationStationName: 'Assembly Line 4',
      status: MissionStatus.completed,
      priority: MissionPriority.normal,
      progressPercent: 100.0,
      payloadWeightKg: 65.0,
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      startedAt: DateTime.now().subtract(const Duration(minutes: 40)),
      completedAt: DateTime.now().subtract(const Duration(minutes: 26)),
    ),
    MissionModel(
      id: 'MSN-1040',
      name: 'Raw Castings Inbound Batch',
      assignedRobotId: 'agv-02',
      assignedRobotName: 'Atlas-02',
      sourceStationId: 'STN-DOCK-1',
      sourceStationName: 'Inbound Dock 1',
      destinationStationId: 'STN-CNC-BAY',
      destinationStationName: 'CNC Machining Bay',
      status: MissionStatus.completed,
      priority: MissionPriority.low,
      progressPercent: 100.0,
      payloadWeightKg: 420.0,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      startedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
      completedAt: DateTime.now().subtract(
        const Duration(hours: 1, minutes: 32),
      ),
    ),
  ];

  final _controller = StreamController<List<MissionModel>>.broadcast();

  @override
  Future<List<MissionModel>> getMissions() async {
    return _missions;
  }

  @override
  Stream<List<MissionModel>> watchMissions() async* {
    yield _missions;
    yield* _controller.stream;
  }

  @override
  Future<MissionModel> createMission({
    required String name,
    required String sourceStationId,
    required String sourceStationName,
    required String destinationStationId,
    required String destinationStationName,
    required MissionPriority priority,
    required double payloadWeightKg,
    String? assignedRobotId,
  }) async {
    final newId = 'MSN-${1045 + _missions.length}';
    final mission = MissionModel(
      id: newId,
      name: name,
      assignedRobotId: assignedRobotId,
      assignedRobotName: assignedRobotId == 'agv-03' ? 'Vanguard-03' : null,
      sourceStationId: sourceStationId,
      sourceStationName: sourceStationName,
      destinationStationId: destinationStationId,
      destinationStationName: destinationStationName,
      status: assignedRobotId != null
          ? MissionStatus.inProgress
          : MissionStatus.queued,
      priority: priority,
      progressPercent: 0.0,
      payloadWeightKg: payloadWeightKg,
      createdAt: DateTime.now(),
      startedAt: assignedRobotId != null ? DateTime.now() : null,
    );

    _missions = [mission, ..._missions];
    _controller.add(_missions);
    return mission;
  }

  @override
  Future<void> cancelMission(String missionId) async {
    _missions = _missions.map((m) {
      if (m.id == missionId) {
        return m.copyWith(status: MissionStatus.cancelled);
      }
      return m;
    }).toList();
    _controller.add(_missions);
  }

  void dispose() {
    _controller.close();
  }
}
