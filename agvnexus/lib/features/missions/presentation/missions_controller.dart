import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../data/mock_mission_repository.dart';
import '../data/supabase_mission_repository.dart';
import '../domain/mission_model.dart';
import '../domain/mission_repository.dart';

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  final client = SupabaseConfig.client;
  if (client != null) {
    return SupabaseMissionRepository(client);
  }
  final repo = MockMissionRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final missionsStreamProvider = StreamProvider<List<MissionModel>>((ref) {
  final repo = ref.watch(missionRepositoryProvider);
  return repo.watchMissions();
});

final activeMissionsProvider = Provider<List<MissionModel>>((ref) {
  final missionsAsync = ref.watch(missionsStreamProvider);
  return missionsAsync.maybeWhen(
    data: (missions) => missions.where((m) => m.isActive).toList(),
    orElse: () => <MissionModel>[],
  );
});

class MissionFilterNotifier extends Notifier<MissionStatus?> {
  @override
  MissionStatus? build() => null;

  void setFilter(MissionStatus? filter) {
    state = filter;
  }
}

final missionFilterStatusProvider =
    NotifierProvider<MissionFilterNotifier, MissionStatus?>(
      MissionFilterNotifier.new,
    );

final filteredMissionsProvider = Provider<List<MissionModel>>((ref) {
  final missionsAsync = ref.watch(missionsStreamProvider);
  final filter = ref.watch(missionFilterStatusProvider);

  return missionsAsync.maybeWhen(
    data: (missions) {
      if (filter == null) return missions;
      return missions.where((m) => m.status == filter).toList();
    },
    orElse: () => <MissionModel>[],
  );
});
