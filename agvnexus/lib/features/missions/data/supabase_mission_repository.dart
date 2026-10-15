import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sp;
import '../domain/mission_model.dart';
import '../domain/mission_repository.dart';
import '../../../core/errors/app_exception.dart';

/// Supabase-backed persistent mission dispatch repository.
/// Manages transport mission requests, status transitions, and audit events.
class SupabaseMissionRepository implements MissionRepository {
  final sp.SupabaseClient _client;

  SupabaseMissionRepository(this._client);

  @override
  Future<List<MissionModel>> getMissions() async {
    try {
      final response = await _client
          .from('missions')
          .select('''
            *,
            robots:robot_id(name),
            pickup_station:pickup_station_id(name),
            dropoff_station:dropoff_station_id(name)
          ''')
          .order('created_at', ascending: false);

      return (response as List)
          .map((row) => MissionModel.fromSupabase(row as Map<String, dynamic>))
          .toList();
    } on sp.PostgrestException catch (e) {
      debugPrint('[SupabaseMissionRepository] Query failed: ${e.message}');
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to query missions: $e');
    }
  }

  @override
  Stream<List<MissionModel>> watchMissions() {
    try {
      return _client
          .from('missions')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .asyncMap((_) => getMissions());
    } catch (e) {
      debugPrint(
        '[SupabaseMissionRepository] Realtime subscription failed: $e',
      );
      return Stream.periodic(
        const Duration(seconds: 4),
      ).asyncMap((_) => getMissions());
    }
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
      // Priority integer mapping (1..4)
      final priorityInt = switch (priority) {
        MissionPriority.low => 1,
        MissionPriority.normal => 2,
        MissionPriority.high => 3,
        MissionPriority.critical => 4,
      };

      // 1. Fetch organization ID from user membership or default fallback
      String orgId = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
      final user = _client.auth.currentUser;
      if (user != null) {
        try {
          final member = await _client
              .from('organization_members')
              .select('organization_id')
              .eq('user_id', user.id)
              .maybeSingle();
          if (member != null && member['organization_id'] != null) {
            orgId = member['organization_id'] as String;
          }
        } catch (_) {}
      }

      final insertData = {
        'organization_id': orgId,
        'pickup_station_id': sourceStationId,
        'dropoff_station_id': destinationStationId,
        'status': 'queued',
        'priority': priorityInt,
        if (assignedRobotId != null) 'robot_id': assignedRobotId,
        if (user != null) 'requested_by': user.id,
      };

      final response = await _client.from('missions').insert(insertData).select(
        '''
            *,
            robots:robot_id(name),
            pickup_station:pickup_station_id(name),
            dropoff_station:dropoff_station_id(name)
          ''',
      ).single();

      final mission = MissionModel.fromSupabase(response);

      // Record dispatch audit event
      try {
        await _client.from('mission_events').insert({
          'organization_id': orgId,
          'mission_id': mission.id,
          'event_type': 'MISSION_QUEUED',
          'message':
              'Mission dispatched from $sourceStationName to $destinationStationName.',
          'metadata': {'payload_kg': payloadWeightKg},
        });
      } catch (err) {
        debugPrint(
          '[SupabaseMissionRepository] Non-fatal mission_event error: $err',
        );
      }

      return mission;
    } on sp.PostgrestException catch (e) {
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to create mission: $e');
    }
  }

  @override
  Future<void> cancelMission(String missionId) async {
    try {
      await _client
          .from('missions')
          .update({
            'status': 'cancelled',
            'completed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', missionId);
    } on sp.PostgrestException catch (e) {
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      throw DatabaseException('Failed to cancel mission: $e');
    }
  }
}
