import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../robots/presentation/robots_controller.dart';
import '../data/telemetry_websocket_client.dart';
import '../domain/telemetry_model.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return const AppConfig();
});

/// Singleton WebSocket client provider connecting to FastAPI gateway.
final telemetryWebSocketClientProvider = Provider<TelemetryWebSocketClient>((
  ref,
) {
  final config = ref.watch(appConfigProvider);
  final user = ref.watch(authStateProvider).asData?.value;

  final client = TelemetryWebSocketClient(
    wsBaseUrl: config.wsBaseUrl,
    authToken: user != null ? 'mock-dev-token' : null,
    initialRobotId: ref.read(selectedRobotIdProvider),
  );

  ref.onDispose(client.dispose);
  return client;
});

/// Live telemetry stream for the currently selected robot.
final liveTelemetryStreamProvider = StreamProvider.autoDispose<TelemetryModel>((
  ref,
) {
  final client = ref.watch(telemetryWebSocketClientProvider);
  final selectedId = ref.watch(selectedRobotIdProvider);

  if (selectedId != null) {
    client.subscribeToRobot(selectedId);
  }

  return client.telemetryStream.where(
    (t) => selectedId == null || t.robotId == selectedId,
  );
});
