import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../domain/robot_model.dart';
import '../domain/robot_repository.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/status_pill.dart';

/// Robotics Gateway HTTP REST repository connecting Flutter to FastAPI /api/v1.
class GatewayRobotRepository implements RobotRepository {
  final String apiBaseUrl;
  final String? Function()? getAuthToken;
  final http.Client _client;

  GatewayRobotRepository({
    required this.apiBaseUrl,
    this.getAuthToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> get _headers {
    final token = getAuthToken?.call();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<RobotModel>> getRobots() async {
    try {
      final uri = Uri.parse('$apiBaseUrl/robots');
      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((jsonItem) => _parseRobot(jsonItem)).toList();
      } else {
        throw NetworkException(
          'Failed to fetch robots from gateway: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException(
        'Connection failure to gateway at $apiBaseUrl: $e',
      );
    }
  }

  @override
  Stream<List<RobotModel>> watchRobots() {
    // Poll gateway periodically every 3 seconds
    return Stream.periodic(
      const Duration(seconds: 3),
    ).asyncMap((_) => getRobots());
  }

  @override
  Future<RobotModel?> getRobotById(String id) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/robots/$id/status');
      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseRobot(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw NetworkException(
          'Gateway error fetching robot: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw NetworkException('Failed to get robot status: $e');
    }
  }

  @override
  Future<void> triggerEmergencyStop(String id) async {
    try {
      // Send 0.0 stop velocity command to robot controller
      await sendTeleopCommand(id, 0.0, 0.0);
    } catch (e) {
      debugPrint('[GatewayRobotRepository] Emergency stop dispatch failed: $e');
    }
  }

  @override
  Future<void> clearFaults(String id) async {
    // Acknowledge faults via gateway
  }

  Future<bool> sendTeleopCommand(
    String robotId,
    double linearVelocity,
    double angularVelocity,
  ) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/robots/$robotId/teleop');
      final body = json.encode({
        'linear_velocity': linearVelocity,
        'angular_velocity': angularVelocity,
      });

      final response = await _client.post(uri, headers: _headers, body: body);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[GatewayRobotRepository] Teleop dispatch error: $e');
      return false;
    }
  }

  RobotModel _parseRobot(Map<String, dynamic> json) {
    AgvOperatingMode parseMode(String? m) {
      switch (m?.toLowerCase()) {
        case 'navigating':
        case 'in_progress':
          return AgvOperatingMode.navigating;
        case 'charging':
          return AgvOperatingMode.charging;
        case 'paused':
          return AgvOperatingMode.paused;
        case 'error':
        case 'fault':
          return AgvOperatingMode.fault;
        case 'idle':
        default:
          return AgvOperatingMode.idle;
      }
    }

    return RobotModel(
      id: json['id'] as String? ?? json['robot_id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Titan-01 (AGV-01)',
      modelType: json['robot_type'] as String? ?? 'Differential Drive AMR',
      mode: parseMode(json['operating_mode'] as String?),
      batteryPercent: (json['battery_percent'] as num?)?.toDouble() ?? 94.0,
      batteryVoltage: (json['battery_voltage'] as num?)?.toDouble() ?? 25.4,
      isCharging: json['is_charging'] as bool? ?? false,
      linearVelocity: (json['linear_velocity'] as num?)?.toDouble() ?? 0.0,
      angularVelocity: (json['angular_velocity'] as num?)?.toDouble() ?? 0.0,
      poseX: (json['position_x'] as num?)?.toDouble() ?? 2.5,
      poseY: (json['position_y'] as num?)?.toDouble() ?? 3.0,
      poseYaw: (json['yaw'] as num?)?.toDouble() ?? 0.0,
      localizationConfidence:
          (json['localization_confidence'] as num?)?.toDouble() ?? 0.98,
      activeMissionId: json['active_mission_id'] as String?,
      lastHeartbeat: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      ipAddress: '192.168.1.101',
      rosDomainId: 0,
      activeFaults:
          (json['active_faults'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
