import 'robot_alert_model.dart';

abstract class AlertRepository {
  Future<List<RobotAlertModel>> getAlerts({bool unacknowledgedOnly = false});
  Stream<List<RobotAlertModel>> watchAlerts();
  Future<void> acknowledgeAlert(String alertId);
}
