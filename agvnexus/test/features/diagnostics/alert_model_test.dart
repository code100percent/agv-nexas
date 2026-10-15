import 'package:flutter_test/flutter_test.dart';
import 'package:agvnexus/features/diagnostics/domain/robot_alert_model.dart';

void main() {
  group('RobotAlertModel Serialization & Severity Tests (Phase 2)', () {
    test('Correctly parses critical alert with unacknowledged status', () {
      final alertRow = {
        'id': 'f0eebc99-9c0b-4ef8-bb6d-6bb9bd380f01',
        'organization_id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'robot_id': 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01',
        'severity': 'critical',
        'title': 'LiDAR Obstruction Detected',
        'description': 'Scanner lens obstructed',
        'acknowledged_at': null,
        'created_at': '2026-03-01T12:00:00.000Z',
        'robots': {'name': 'Titan-01'},
      };

      final alert = RobotAlertModel.fromSupabase(alertRow);
      expect(alert.id, 'f0eebc99-9c0b-4ef8-bb6d-6bb9bd380f01');
      expect(alert.severity, AlertSeverity.critical);
      expect(alert.robotName, 'Titan-01');
      expect(alert.isAcknowledged, isFalse);
    });

    test('Identifies acknowledged alert with timestamp', () {
      final ackRow = {
        'id': 'f0eebc99-9c0b-4ef8-bb6d-6bb9bd380f02',
        'organization_id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'robot_id': 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b02',
        'severity': 'warning',
        'title': 'Low Battery Threshold (15%)',
        'acknowledged_at': '2026-03-01T12:05:00.000Z',
        'acknowledged_by': 'usr-op-01',
        'created_at': '2026-03-01T12:00:00.000Z',
      };

      final alert = RobotAlertModel.fromSupabase(ackRow);
      expect(alert.isAcknowledged, isTrue);
      expect(alert.severity, AlertSeverity.warning);
      expect(alert.acknowledgedBy, 'usr-op-01');
    });
  });
}
