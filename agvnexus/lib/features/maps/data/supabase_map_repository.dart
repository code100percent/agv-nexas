import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sp;
import '../domain/map_model.dart';
import '../domain/map_repository.dart';
import '../../../core/errors/app_exception.dart';

/// Supabase-backed persistent factory map & station repository.
/// Reads 2D metric occupancy grid metadata and designated factory stations.
class SupabaseMapRepository implements MapRepository {
  final sp.SupabaseClient _client;

  SupabaseMapRepository(this._client);

  @override
  Future<List<StationModel>> getStations() async {
    try {
      final response = await _client
          .from('stations')
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((row) => StationModel.fromSupabase(row as Map<String, dynamic>))
          .toList();
    } on sp.PostgrestException catch (e) {
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to load stations: $e');
    }
  }

  @override
  Future<FactoryMapModel> getActiveMap() async {
    try {
      final mapResponse = await _client
          .from('factory_maps')
          .select()
          .limit(1)
          .maybeSingle();

      if (mapResponse == null) {
        throw const NotFoundException(
          'No active factory map configured in database.',
        );
      }

      final stations = await getStations();
      return FactoryMapModel.fromSupabase(mapResponse, stations: stations);
    } on sp.PostgrestException catch (e) {
      debugPrint('[SupabaseMapRepository] Map query error: ${e.message}');
      throw DatabaseException(e.message, code: e.code);
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to load active map: $e');
    }
  }
}
