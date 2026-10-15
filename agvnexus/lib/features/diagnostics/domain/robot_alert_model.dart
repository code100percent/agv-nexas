enum AlertSeverity {
  critical('CRITICAL'),
  warning('WARNING'),
  info('INFO');

  final String label;
  const AlertSeverity(this.label);

  static AlertSeverity fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'critical':
        return AlertSeverity.critical;
      case 'warning':
        return AlertSeverity.warning;
      case 'info':
      default:
        return AlertSeverity.info;
    }
  }
}

class RobotAlertModel {
  final String id;
  final String organizationId;
  final String robotId;
  final String? robotName;
  final AlertSeverity severity;
  final String title;
  final String? description;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final DateTime createdAt;

  const RobotAlertModel({
    required this.id,
    required this.organizationId,
    required this.robotId,
    this.robotName,
    required this.severity,
    required this.title,
    this.description,
    this.acknowledgedAt,
    this.acknowledgedBy,
    required this.createdAt,
  });

  bool get isAcknowledged => acknowledgedAt != null;

  factory RobotAlertModel.fromSupabase(Map<String, dynamic> map) {
    final robotMap = map['robots'] as Map<String, dynamic>?;
    final ackStr = map['acknowledged_at'] as String?;
    final createdStr = map['created_at'] as String?;

    return RobotAlertModel(
      id: map['id'] as String,
      organizationId: map['organization_id'] as String? ?? '',
      robotId: map['robot_id'] as String,
      robotName: robotMap?['name'] as String?,
      severity: AlertSeverity.fromString(map['severity'] as String?),
      title: map['title'] as String? ?? 'Fleet Alert',
      description: map['description'] as String?,
      acknowledgedAt: ackStr != null ? DateTime.parse(ackStr) : null,
      acknowledgedBy: map['acknowledged_by'] as String?,
      createdAt: createdStr != null
          ? DateTime.parse(createdStr)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'organizationId': organizationId,
      'robotId': robotId,
      'robotName': robotName,
      'severity': severity.name,
      'title': title,
      'description': description,
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'acknowledgedBy': acknowledgedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
