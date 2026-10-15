import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sp;
import '../domain/robot_model.dart';
import '../domain/robot_repository.dart';
import '../../../core/errors/app_exception.dart';

/// Supabase-backed persistent robot fleet repository.
/// Reads registered AMR metadata from the PostgreSQL `robots` table with RLS enforcement.
class SupabaseRobotRepository implements RobotRepository {
  final sp.SupabaseClient _client;

  SupabaseRobotRepository(this._client);

  @override
  Future<List<RobotModel>> getRobots() async {
    try {
      final response = await _client
          .from('robots')
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((row) => RobotModel.fromSupabase(row as Map<String, dynamic>))
          .toList();
    } on sp.PostgrestException catch (e) {
      debugPrint('[SupabaseRobotRepository] PostgrestException: ${e.message}');
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to query robot fleet: $e');
    }
  }

  @override
  Stream<List<RobotModel>> watchRobots() {
    try {
      return _client
          .from('robots')
          .stream(primaryKey: ['id'])
          .order('name', ascending: true)
          .map((records) => records.map(RobotModel.fromSupabase).toList());
    } catch (e) {
      debugPrint(
        '[SupabaseRobotRepository] Realtime stream failed: $e, falling back to polling.',
      );
      return Stream.periodic(
        const Duration(seconds: 3),
      ).asyncMap((_) => getRobots());
    }
  }

  @override
  Future<RobotModel?> getRobotById(String id) async {
    try {
      final response = await _client
          .from('robots')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return RobotModel.fromSupabase(response);
    } catch (e) {
      throw DatabaseException('Failed to fetch AMR record: $e');
    }
  }

  @override
  Future<void> triggerEmergencyStop(String id) async {
    try {
      // In Phase 2: Log emergency stop event to mission_events / robot_alerts
      await _client.from('robot_alerts').insert({
        'robot_id': id,
        'severity': 'critical',
        'title': 'Software E-Stop Commanded',
        'description':
            'Operator requested emergency stop via AGV Nexus command center.',
      });
    } catch (e) {
      debugPrint('[SupabaseRobotRepository] Alert insertion failed: $e');
    }
  }

  @override
  Future<void> clearFaults(String id) async {
    try {
      // Acknowledge all active alerts for this robot
      await _client
          .from('robot_alerts')
          .update({'acknowledged_at': DateTime.now().toUtc().toIso8601String()})
          .eq('robot_id', id)
          .isFilter('acknowledged_at', null);
    } catch (e) {
      debugPrint('[SupabaseRobotRepository] Clear faults failed: $e');
    }
  }
}
