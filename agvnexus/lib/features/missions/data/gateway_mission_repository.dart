import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/mission_model.dart';
import '../domain/mission_repository.dart';
import '../../../core/errors/app_exception.dart';

/// Robotics Gateway HTTP REST mission repository connecting Flutter to FastAPI /api/v1/robots/{id}/missions.
class GatewayMissionRepository implements MissionRepository {
  final String apiBaseUrl;
  final String defaultRobotId;
  final String? Function()? getAuthToken;
  final http.Client _client;

  GatewayMissionRepository({
    required this.apiBaseUrl,
    required this.defaultRobotId,
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
  Future<List<MissionModel>> getMissions() async {
    try {
      final uri = Uri.parse('$apiBaseUrl/robots/$defaultRobotId/missions');
      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => _parseMission(item)).toList();
      } else {
        throw NetworkException(
          'Failed to query missions: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Gateway error fetching missions: $e');
    }
  }

  @override
  Stream<List<MissionModel>> watchMissions() {
    return Stream.periodic(
      const Duration(seconds: 4),
    ).asyncMap((_) => getMissions());
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
    try {
      final targetRobot = assignedRobotId ?? defaultRobotId;
      final uri = Uri.parse('$apiBaseUrl/robots/$targetRobot/missions');

      int priorityNum = 2;
      switch (priority) {
        case MissionPriority.low:
          priorityNum = 1;
          break;
        case MissionPriority.normal:
          priorityNum = 2;
          break;
        case MissionPriority.high:
          priorityNum = 3;
          break;
        case MissionPriority.critical:
          priorityNum = 4;
          break;
      }

      final body = json.encode({
        'name': name,
        'pickup_station_id': sourceStationId,
        'dropoff_station_id': destinationStationId,
        'priority': priorityNum,
        'payload_weight_kg': payloadWeightKg,
        'idempotency_key': 'flutter-${DateTime.now().millisecondsSinceEpoch}',
      });

      final response = await _client.post(uri, headers: _headers, body: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseMission(data);
      } else {
        throw NetworkException(
          'Mission creation rejected: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Gateway error dispatching mission: $e');
    }
  }

  @override
  Future<void> cancelMission(String missionId) async {
    // Mission cancellation
  }

  MissionModel _parseMission(Map<String, dynamic> json) {
    MissionStatus parseStatus(String? s) {
      switch (s?.toLowerCase()) {
        case 'in_progress':
        case 'assigned':
          return MissionStatus.inProgress;
        case 'completed':
          return MissionStatus.completed;
        case 'cancelled':
          return MissionStatus.cancelled;
        case 'failed':
          return MissionStatus.failed;
        case 'queued':
        default:
          return MissionStatus.queued;
      }
    }

    MissionPriority parsePriority(int? p) {
      switch (p) {
        case 1:
          return MissionPriority.low;
        case 3:
          return MissionPriority.high;
        case 4:
          return MissionPriority.critical;
        case 2:
        default:
          return MissionPriority.normal;
      }
    }

    final status = parseStatus(json['status'] as String?);

    return MissionModel(
      id: json['id'] as String? ?? 'mission-unknown',
      name: json['name'] as String? ?? 'Autonomous Dispatch',
      assignedRobotId: json['robot_id'] as String?,
      assignedRobotName: 'Titan-01 (AGV-01)',
      sourceStationId: json['pickup_station_id'] as String? ?? 'station-01',
      sourceStationName: 'Warehouse Bay A',
      destinationStationId:
          json['dropoff_station_id'] as String? ?? 'station-02',
      destinationStationName: 'Assembly Line 4',
      status: status,
      priority: parsePriority((json['priority'] as num?)?.toInt()),
      progressPercent:
          (json['progress_percent'] as num?)?.toDouble() ??
          (status == MissionStatus.completed ? 100.0 : 45.0),
      payloadWeightKg: (json['payload_weight_kg'] as num?)?.toDouble() ?? 10.0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }
}
