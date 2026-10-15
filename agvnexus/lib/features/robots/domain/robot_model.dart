import '../../../core/widgets/status_pill.dart';

/// Industrial Autonomous Mobile Robot domain model.
class RobotModel {
  final String id;
  final String name;
  final String modelType;
  final AgvOperatingMode mode;
  final double batteryPercent;
  final double batteryVoltage;
  final bool isCharging;
  final double linearVelocity; // m/s
  final double angularVelocity; // rad/s
  final double poseX; // meters in map frame
  final double poseY; // meters in map frame
  final double poseYaw; // radians
  final double localizationConfidence; // 0.0 to 1.0
  final String? activeMissionId;
  final DateTime lastHeartbeat;
  final String ipAddress;
  final int rosDomainId;
  final List<String> activeFaults;

  const RobotModel({
    required this.id,
    required this.name,
    required this.modelType,
    required this.mode,
    required this.batteryPercent,
    required this.batteryVoltage,
    required this.isCharging,
    required this.linearVelocity,
    required this.angularVelocity,
    required this.poseX,
    required this.poseY,
    required this.poseYaw,
    required this.localizationConfidence,
    this.activeMissionId,
    required this.lastHeartbeat,
    required this.ipAddress,
    required this.rosDomainId,
    this.activeFaults = const [],
  });

  bool get isConnected =>
      DateTime.now().difference(lastHeartbeat).inSeconds < 10;

  bool get hasFaults => activeFaults.isNotEmpty;

  RobotModel copyWith({
    String? id,
    String? name,
    String? modelType,
    AgvOperatingMode? mode,
    double? batteryPercent,
    double? batteryVoltage,
    bool? isCharging,
    double? linearVelocity,
    double? angularVelocity,
    double? poseX,
    double? poseY,
    double? poseYaw,
    double? localizationConfidence,
    String? activeMissionId,
    DateTime? lastHeartbeat,
    String? ipAddress,
    int? rosDomainId,
    List<String>? activeFaults,
  }) {
    return RobotModel(
      id: id ?? this.id,
      name: name ?? this.name,
      modelType: modelType ?? this.modelType,
      mode: mode ?? this.mode,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      isCharging: isCharging ?? this.isCharging,
      linearVelocity: linearVelocity ?? this.linearVelocity,
      angularVelocity: angularVelocity ?? this.angularVelocity,
      poseX: poseX ?? this.poseX,
      poseY: poseY ?? this.poseY,
      poseYaw: poseYaw ?? this.poseYaw,
      localizationConfidence:
          localizationConfidence ?? this.localizationConfidence,
      activeMissionId: activeMissionId ?? this.activeMissionId,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
      ipAddress: ipAddress ?? this.ipAddress,
      rosDomainId: rosDomainId ?? this.rosDomainId,
      activeFaults: activeFaults ?? this.activeFaults,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'modelType': modelType,
      'mode': mode.name,
      'batteryPercent': batteryPercent,
      'batteryVoltage': batteryVoltage,
      'isCharging': isCharging,
      'linearVelocity': linearVelocity,
      'angularVelocity': angularVelocity,
      'poseX': poseX,
      'poseY': poseY,
      'poseYaw': poseYaw,
      'localizationConfidence': localizationConfidence,
      'activeMissionId': activeMissionId,
      'lastHeartbeat': lastHeartbeat.toIso8601String(),
      'ipAddress': ipAddress,
      'rosDomainId': rosDomainId,
      'activeFaults': activeFaults,
    };
  }

  factory RobotModel.fromSupabase(Map<String, dynamic> map) {
    final lastSeenStr = map['last_seen_at'] as String?;
    final lastSeen = lastSeenStr != null
        ? DateTime.parse(lastSeenStr)
        : DateTime.now().subtract(const Duration(minutes: 5));

    return RobotModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Unnamed AGV',
      modelType: map['robot_type'] as String? ?? 'differential_drive',
      mode: AgvOperatingMode.idle,
      batteryPercent: 88.0,
      batteryVoltage: 27.2,
      isCharging: false,
      linearVelocity: 0.0,
      angularVelocity: 0.0,
      poseX: 2.5,
      poseY: 3.0,
      poseYaw: 0.0,
      localizationConfidence: 0.98,
      lastHeartbeat: lastSeen,
      ipAddress:
          '192.168.1.${(map['robot_code'] as String? ?? '10').replaceAll(RegExp(r'[^0-9]'), '')}',
      rosDomainId: 10,
      activeFaults: const [],
    );
  }
}
