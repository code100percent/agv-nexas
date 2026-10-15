import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agvnexus/app/app.dart';
import 'package:agvnexus/features/auth/data/mock_auth_repository.dart';
import 'package:agvnexus/features/auth/presentation/auth_controller.dart';

void main() {
  testWidgets('App redirects unauthenticated user to /sign-in', (
    WidgetTester tester,
  ) async {
    final mockAuth = MockAuthRepository(startAuthenticated: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(mockAuth)],
        child: const AgvNexusApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OPERATOR SIGN-IN'), findsOneWidget);
    expect(find.text('AGV NEXUS'), findsOneWidget);
  });

  testWidgets('Desktop layout renders NavigationRail and context top bar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockAuth = MockAuthRepository(startAuthenticated: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(mockAuth)],
        child: const AgvNexusApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('OPERATIONS OVERVIEW'), findsOneWidget);
    expect(find.text('COMMAND CENTER'), findsOneWidget);
    expect(find.text('Live 2D Map'), findsOneWidget);
    expect(find.text('Robot Fleet'), findsOneWidget);
    expect(find.text('Missions'), findsOneWidget);
  });

  testWidgets('Mobile layout renders Bottom Navigation Bar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockAuth = MockAuthRepository(startAuthenticated: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(mockAuth)],
        child: const AgvNexusApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Fleet'), findsOneWidget);
  });
}
