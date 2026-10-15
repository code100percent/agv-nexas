import 'package:flutter/foundation.dart';

/// Typed domain model representing an instantaneous telemetry sample from the robot.
@immutable
class TelemetryModel {
  final String robotId;
  final DateTime timestamp;
  final String source; // 'ros2', 'simulated', 'disconnected'
  final String connectionState; // 'connected', 'disconnected', 'reconnecting'
  final String dataFreshness; // 'fresh', 'stale'
  final double? positionX;
  final double? positionY;
  final double? positionZ;
  final double? yaw;
  final double? linearVelocity;
  final double? angularVelocity;
  final int? leftWheelTicks;
  final int? rightWheelTicks;
  final double? batteryPercent;
  final double? batteryVoltage;
  final bool isCharging;
  final String operatingState;
  final double localizationConfidence;
  final String? activeMissionId;
  final List<String> activeFaults;

  const TelemetryModel({
    required this.robotId,
    required this.timestamp,
    required this.source,
    required this.connectionState,
    required this.dataFreshness,
    this.positionX,
    this.positionY,
    this.positionZ,
    this.yaw,
    this.linearVelocity,
    this.angularVelocity,
    this.leftWheelTicks,
    this.rightWheelTicks,
    this.batteryPercent,
    this.batteryVoltage,
    this.isCharging = false,
    this.operatingState = 'idle',
    this.localizationConfidence = 1.0,
    this.activeMissionId,
    this.activeFaults = const [],
  });

  bool get isConnected => connectionState == 'connected';
  bool get isFresh => dataFreshness == 'fresh';
  bool get isSimulated => source == 'simulated';

  factory TelemetryModel.fromJson(Map<String, dynamic> json) {
    return TelemetryModel(
      robotId: json['robot_id'] as String? ?? 'unknown',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      source: json['source'] as String? ?? 'simulated',
      connectionState: json['connection_state'] as String? ?? 'disconnected',
      dataFreshness: json['data_freshness'] as String? ?? 'stale',
      positionX: (json['position_x'] as num?)?.toDouble(),
      positionY: (json['position_y'] as num?)?.toDouble(),
      positionZ: (json['position_z'] as num?)?.toDouble() ?? 0.0,
      yaw: (json['yaw'] as num?)?.toDouble(),
      linearVelocity: (json['linear_velocity'] as num?)?.toDouble(),
      angularVelocity: (json['angular_velocity'] as num?)?.toDouble(),
      leftWheelTicks: (json['left_wheel_ticks'] as num?)?.toInt(),
      rightWheelTicks: (json['right_wheel_ticks'] as num?)?.toInt(),
      batteryPercent: (json['battery_percentage'] as num?)?.toDouble(),
      batteryVoltage: (json['battery_voltage'] as num?)?.toDouble(),
      isCharging: json['is_charging'] as bool? ?? false,
      operatingState: json['robot_operating_state'] as String? ?? 'idle',
      localizationConfidence:
          (json['localization_confidence'] as num?)?.toDouble() ?? 1.0,
      activeMissionId: json['active_mission_id'] as String?,
      activeFaults:
          (json['active_faults'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'robot_id': robotId,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      'connection_state': connectionState,
      'data_freshness': dataFreshness,
      'position_x': positionX,
      'position_y': positionY,
      'position_z': positionZ,
      'yaw': yaw,
      'linear_velocity': linearVelocity,
      'angular_velocity': angularVelocity,
      'left_wheel_ticks': leftWheelTicks,
      'right_wheel_ticks': rightWheelTicks,
      'battery_percentage': batteryPercent,
      'battery_voltage': batteryVoltage,
      'is_charging': isCharging,
      'robot_operating_state': operatingState,
      'localization_confidence': localizationConfidence,
      'active_mission_id': activeMissionId,
      'active_faults': activeFaults,
    };
  }
}
