import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sp;
import '../domain/robot_alert_model.dart';
import '../domain/alert_repository.dart';
import '../../../core/errors/app_exception.dart';

/// Supabase-backed persistent fleet diagnostics and safety alert repository.
class SupabaseAlertRepository implements AlertRepository {
  final sp.SupabaseClient _client;

  SupabaseAlertRepository(this._client);

  @override
  Future<List<RobotAlertModel>> getAlerts({
    bool unacknowledgedOnly = false,
  }) async {
    try {
      var query = _client.from('robot_alerts').select('*, robots(name)');
      if (unacknowledgedOnly) {
        query = query.isFilter('acknowledged_at', null);
      }
      final response = await query.order('created_at', ascending: false);
      return (response as List)
          .map(
            (row) => RobotAlertModel.fromSupabase(row as Map<String, dynamic>),
          )
          .toList();
    } on sp.PostgrestException catch (e) {
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to query robot alerts: $e');
    }
  }

  @override
  Stream<List<RobotAlertModel>> watchAlerts() {
    try {
      return _client
          .from('robot_alerts')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .asyncMap((_) => getAlerts());
    } catch (e) {
      debugPrint(
        '[SupabaseAlertRepository] Realtime alerts subscription failed: $e',
      );
      return Stream.periodic(
        const Duration(seconds: 5),
      ).asyncMap((_) => getAlerts());
    }
  }

  @override
  Future<void> acknowledgeAlert(String alertId) async {
    try {
      final user = _client.auth.currentUser;
      await _client
          .from('robot_alerts')
          .update({
            'acknowledged_at': DateTime.now().toUtc().toIso8601String(),
            if (user != null) 'acknowledged_by': user.id,
          })
          .eq('id', alertId);
    } on sp.PostgrestException catch (e) {
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      throw DatabaseException('Failed to acknowledge alert: $e');
    }
  }
}
