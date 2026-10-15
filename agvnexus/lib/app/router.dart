import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/app_shell.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/overview/presentation/overview_screen.dart';
import '../features/maps/presentation/live_map_screen.dart';
import '../features/digital_twin/presentation/digital_twin_screen.dart';
import '../features/robots/presentation/robot_fleet_screen.dart';
import '../features/robots/presentation/robot_detail_screen.dart';
import '../features/missions/presentation/mission_list_screen.dart';
import '../features/telemetry/presentation/telemetry_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shellNav');

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/overview',
    redirect: (context, state) {
      final isAuth = authState.asData?.value != null;
      final isSignInLocation = state.uri.toString() == '/sign-in';

      if (!isAuth && !isSignInLocation) {
        return '/sign-in';
      }
      if (isAuth && isSignInLocation) {
        return '/overview';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/overview',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: OverviewScreen()),
          ),
          GoRoute(
            path: '/map',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LiveMapScreen()),
          ),
          GoRoute(
            path: '/digital-twin',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DigitalTwinScreen()),
          ),
          GoRoute(
            path: '/robots',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: RobotFleetScreen()),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? 'agv-01';
                  return RobotDetailScreen(robotId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/missions',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MissionListScreen()),
          ),
          GoRoute(
            path: '/telemetry',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TelemetryScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});
