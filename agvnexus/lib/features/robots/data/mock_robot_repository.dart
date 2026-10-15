import 'dart:async';
import 'dart:math';
import '../domain/robot_model.dart';
import '../domain/robot_repository.dart';
import '../../../core/widgets/status_pill.dart';

/// Phase 1 Deterministic Mock Robot Repository.
/// Simulates fleet telemetry updates deterministically for testing and UI evaluation.
class MockRobotRepository implements RobotRepository {
  List<RobotModel> _robots = [
    RobotModel(
      id: 'agv-01',
      name: 'Titan-01',
      modelType: 'Differential Drive 500kg',
      mode: AgvOperatingMode.navigating,
      batteryPercent: 84.5,
      batteryVoltage: 25.6,
      isCharging: false,
      linearVelocity: 0.65,
      angularVelocity: 0.05,
      poseX: 12.4,
      poseY: 8.7,
      poseYaw: 0.78,
      localizationConfidence: 0.96,
      activeMissionId: 'MSN-1042',
      lastHeartbeat: DateTime.now(),
      ipAddress: '192.168.10.101',
      rosDomainId: 42,
      activeFaults: [],
    ),
    RobotModel(
      id: 'agv-02',
      name: 'Atlas-02',
      modelType: 'Differential Drive 500kg',
      mode: AgvOperatingMode.charging,
      batteryPercent: 98.0,
      batteryVoltage: 27.2,
      isCharging: true,
      linearVelocity: 0.0,
      angularVelocity: 0.0,
      poseX: 2.0,
      poseY: 3.5,
      poseYaw: 3.14,
      localizationConfidence: 0.99,
      activeMissionId: null,
      lastHeartbeat: DateTime.now(),
      ipAddress: '192.168.10.102',
      rosDomainId: 42,
      activeFaults: [],
    ),
    RobotModel(
      id: 'agv-03',
      name: 'Vanguard-03',
      modelType: 'Compact AMR 250kg',
      mode: AgvOperatingMode.idle,
      batteryPercent: 71.8,
      batteryVoltage: 24.8,
      isCharging: false,
      linearVelocity: 0.0,
      angularVelocity: 0.0,
      poseX: 24.5,
      poseY: 15.2,
      poseYaw: 1.57,
      localizationConfidence: 0.94,
      activeMissionId: null,
      lastHeartbeat: DateTime.now(),
      ipAddress: '192.168.10.103',
      rosDomainId: 42,
      activeFaults: [],
    ),
    RobotModel(
      id: 'agv-04',
      name: 'Hermes-04',
      modelType: 'Heavy Tug 1000kg',
      mode: AgvOperatingMode.fault,
      batteryPercent: 42.0,
      batteryVoltage: 23.4,
      isCharging: false,
      linearVelocity: 0.0,
      angularVelocity: 0.0,
      poseX: 18.0,
      poseY: 4.2,
      poseYaw: 0.0,
      localizationConfidence: 0.81,
      activeMissionId: null,
      lastHeartbeat: DateTime.now().subtract(const Duration(seconds: 4)),
      ipAddress: '192.168.10.104',
      rosDomainId: 42,
      activeFaults: ['E-204: Front LiDAR Optical Window Obstructed'],
    ),
  ];

  final _controller = StreamController<List<RobotModel>>.broadcast();
  Timer? _simulationTimer;
  double _simAngle = 0.0;

  MockRobotRepository({bool enableTicker = true}) {
    if (enableTicker) {
      _startSimulationTicker();
    }
  }

  void _startSimulationTicker() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _simAngle += 0.05;
      if (_simAngle > 2 * pi) _simAngle = 0.0;

      _robots = _robots.map((r) {
        if (r.id == 'agv-01' && r.mode == AgvOperatingMode.navigating) {
          // Smooth simulated circular/patrol motion for UI testing
          final newX = 12.0 + 4.0 * cos(_simAngle);
          final newY = 8.0 + 3.0 * sin(_simAngle);
          final newYaw = _simAngle + pi / 2;
          return r.copyWith(
            poseX: double.parse(newX.toStringAsFixed(2)),
            poseY: double.parse(newY.toStringAsFixed(2)),
            poseYaw: double.parse(newYaw.toStringAsFixed(2)),
            lastHeartbeat: DateTime.now(),
          );
        }
        return r.copyWith(lastHeartbeat: DateTime.now());
      }).toList();

      _controller.add(_robots);
    });
  }

  @override
  Future<List<RobotModel>> getRobots() async {
    return _robots;
  }

  @override
  Stream<List<RobotModel>> watchRobots() async* {
    yield _robots;
    yield* _controller.stream;
  }

  @override
  Future<RobotModel?> getRobotById(String id) async {
    try {
      return _robots.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> triggerEmergencyStop(String id) async {
    _robots = _robots.map((r) {
      if (r.id == id) {
        return r.copyWith(
          mode: AgvOperatingMode.estop,
          linearVelocity: 0.0,
          angularVelocity: 0.0,
          activeFaults: [
            ...r.activeFaults,
            'E-999: Software Emergency Stop Commanded',
          ],
        );
      }
      return r;
    }).toList();
    _controller.add(_robots);
  }

  @override
  Future<void> clearFaults(String id) async {
    _robots = _robots.map((r) {
      if (r.id == id) {
        return r.copyWith(mode: AgvOperatingMode.idle, activeFaults: []);
      }
      return r;
    }).toList();
    _controller.add(_robots);
  }

  void dispose() {
    _simulationTimer?.cancel();
    _controller.close();
  }
}
