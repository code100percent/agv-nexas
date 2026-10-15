import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/config/app_config.dart';
import '../data/gateway_robot_repository.dart';
import '../data/mock_robot_repository.dart';
import '../data/supabase_robot_repository.dart';
import '../domain/robot_model.dart';
import '../domain/robot_repository.dart';

final gatewayRobotRepositoryProvider = Provider<GatewayRobotRepository>((ref) {
  const config = AppConfig();
  return GatewayRobotRepository(apiBaseUrl: config.apiBaseUrl);
});

final robotRepositoryProvider = Provider<RobotRepository>((ref) {
  final client = SupabaseConfig.client;
  if (client != null) {
    return SupabaseRobotRepository(client);
  }
  final repo = MockRobotRepository(enableTicker: true);
  ref.onDispose(repo.dispose);
  return repo;
});

final robotsStreamProvider = StreamProvider<List<RobotModel>>((ref) {
  final repo = ref.watch(robotRepositoryProvider);
  return repo.watchRobots();
});

class SelectedRobotIdNotifier extends Notifier<String?> {
  @override
  String? build() => 'agv-01';

  void select(String? id) {
    state = id;
  }
}

final selectedRobotIdProvider =
    NotifierProvider<SelectedRobotIdNotifier, String?>(
      SelectedRobotIdNotifier.new,
    );

final selectedRobotProvider = Provider<RobotModel?>((ref) {
  final robotsAsync = ref.watch(robotsStreamProvider);
  final selectedId = ref.watch(selectedRobotIdProvider);

  return robotsAsync.maybeWhen(
    data: (robots) {
      if (selectedId == null) return robots.isNotEmpty ? robots.first : null;
      try {
        return robots.firstWhere((r) => r.id == selectedId);
      } catch (_) {
        return robots.isNotEmpty ? robots.first : null;
      }
    },
    orElse: () => null,
  );
});
