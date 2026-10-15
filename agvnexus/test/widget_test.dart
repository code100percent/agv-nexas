import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agvnexus/features/auth/presentation/sign_in_screen.dart';
import 'package:agvnexus/core/widgets/connection_badge.dart';
import 'package:agvnexus/core/network/connection_state.dart';

void main() {
  testWidgets(
    'ConnectionBadge displays SIMULATED / DEMO for simulated status',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConnectionBadge(status: ConnectionStatus.simulated),
          ),
        ),
      );

      expect(find.text('SIMULATED / DEMO'), findsOneWidget);
    },
  );

  testWidgets(
    'SignInScreen renders industrial title and demo persona options',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SignInScreen())),
      );
      await tester.pumpAndSettle();

      expect(find.text('AGV NEXUS'), findsOneWidget);
      expect(find.text('OPERATOR SIGN-IN'), findsOneWidget);
      expect(find.text('AUTHORIZE SESSION'), findsOneWidget);
      expect(find.text('Factory Operator'), findsOneWidget);
      expect(find.text('Robotics Engineer'), findsOneWidget);
    },
  );
}
