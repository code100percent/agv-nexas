import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum MissionStatus {
  queued,
  inProgress,
  completed,
  cancelled,
  failed;

  String get displayName {
    switch (this) {
      case MissionStatus.queued:
        return 'QUEUED';
      case MissionStatus.inProgress:
        return 'IN PROGRESS';
      case MissionStatus.completed:
        return 'COMPLETED';
      case MissionStatus.cancelled:
        return 'CANCELLED';
      case MissionStatus.failed:
        return 'FAILED';
    }
  }

  Color get color {
    switch (this) {
      case MissionStatus.queued:
        return AppColors.textSecondary;
      case MissionStatus.inProgress:
        return AppColors.primary;
      case MissionStatus.completed:
        return AppColors.success;
      case MissionStatus.cancelled:
        return AppColors.warning;
      case MissionStatus.failed:
        return AppColors.error;
    }
  }
}

enum MissionPriority {
  low('LOW', AppColors.textSecondary),
  normal('NORMAL', AppColors.info),
  high('HIGH', AppColors.warning),
  critical('CRITICAL', AppColors.error);

  final String label;
  final Color color;
  const MissionPriority(this.label, this.color);
}

/// AGV Pickup-and-Delivery mission domain model.
class MissionModel {
  final String id;
  final String name;
  final String? assignedRobotId;
  final String? assignedRobotName;
  final String sourceStationId;
  final String sourceStationName;
  final String destinationStationId;
  final String destinationStationName;
  final MissionStatus status;
  final MissionPriority priority;
  final double progressPercent; // 0.0 to 100.0
  final double payloadWeightKg;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const MissionModel({
    required this.id,
    required this.name,
    this.assignedRobotId,
    this.assignedRobotName,
    required this.sourceStationId,
    required this.sourceStationName,
    required this.destinationStationId,
    required this.destinationStationName,
    required this.status,
    required this.priority,
    required this.progressPercent,
    required this.payloadWeightKg,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  bool get isActive =>
      status == MissionStatus.inProgress || status == MissionStatus.queued;

  MissionModel copyWith({
    String? id,
    String? name,
    String? assignedRobotId,
    String? assignedRobotName,
    String? sourceStationId,
    String? sourceStationName,
    String? destinationStationId,
    String? destinationStationName,
    MissionStatus? status,
    MissionPriority? priority,
    double? progressPercent,
    double? payloadWeightKg,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return MissionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      assignedRobotId: assignedRobotId ?? this.assignedRobotId,
      assignedRobotName: assignedRobotName ?? this.assignedRobotName,
      sourceStationId: sourceStationId ?? this.sourceStationId,
      sourceStationName: sourceStationName ?? this.sourceStationName,
      destinationStationId: destinationStationId ?? this.destinationStationId,
      destinationStationName:
          destinationStationName ?? this.destinationStationName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      progressPercent: progressPercent ?? this.progressPercent,
      payloadWeightKg: payloadWeightKg ?? this.payloadWeightKg,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'assignedRobotId': assignedRobotId,
      'assignedRobotName': assignedRobotName,
      'sourceStationId': sourceStationId,
      'sourceStationName': sourceStationName,
      'destinationStationId': destinationStationId,
      'destinationStationName': destinationStationName,
      'status': status.name,
      'priority': priority.label,
      'progressPercent': progressPercent,
      'payloadWeightKg': payloadWeightKg,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory MissionModel.fromSupabase(Map<String, dynamic> map) {
    // Map status string
    MissionStatus parseStatus(String? statusStr) {
      switch (statusStr?.toLowerCase()) {
        case 'in_progress':
          return MissionStatus.inProgress;
        case 'completed':
          return MissionStatus.completed;
        case 'cancelled':
          return MissionStatus.cancelled;
        case 'failed':
          return MissionStatus.failed;
        case 'assigned':
        case 'queued':
        default:
          return MissionStatus.queued;
      }
    }

    // Map priority integer (1..4)
    MissionPriority parsePriority(dynamic p) {
      final val = p is int ? p : int.tryParse(p?.toString() ?? '2') ?? 2;
      switch (val) {
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

    final createdAtStr = map['created_at'] as String?;
    final startedAtStr = map['started_at'] as String?;
    final completedAtStr = map['completed_at'] as String?;

    final robotMap = map['robots'] as Map<String, dynamic>?;
    final pickupMap = map['pickup_station'] as Map<String, dynamic>?;
    final dropoffMap = map['dropoff_station'] as Map<String, dynamic>?;

    final status = parseStatus(map['status'] as String?);
    final progress = status == MissionStatus.completed
        ? 100.0
        : status == MissionStatus.inProgress
        ? 45.0
        : 0.0;

    return MissionModel(
      id: map['id'] as String,
      name: 'Mission ${(map['id'] as String).substring(0, 8).toUpperCase()}',
      assignedRobotId: map['robot_id'] as String?,
      assignedRobotName: robotMap?['name'] as String?,
      sourceStationId: map['pickup_station_id'] as String? ?? 'bay-a',
      sourceStationName: pickupMap?['name'] as String? ?? 'Warehouse Bay A',
      destinationStationId: map['dropoff_station_id'] as String? ?? 'line-4',
      destinationStationName:
          dropoffMap?['name'] as String? ?? 'Assembly Line 4',
      status: status,
      priority: parsePriority(map['priority']),
      progressPercent: progress,
      payloadWeightKg: (map['payload_kg'] as num?)?.toDouble() ?? 12.0,
      createdAt: createdAtStr != null
          ? DateTime.parse(createdAtStr)
          : DateTime.now(),
      startedAt: startedAtStr != null ? DateTime.parse(startedAtStr) : null,
      completedAt: completedAtStr != null
          ? DateTime.parse(completedAtStr)
          : null,
    );
  }
}
