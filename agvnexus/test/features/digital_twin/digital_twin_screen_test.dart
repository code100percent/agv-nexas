import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agvnexus/features/digital_twin/presentation/digital_twin_screen.dart';
import 'package:agvnexus/features/digital_twin/presentation/widgets/isometric_viewport_painter.dart';
import 'package:agvnexus/features/robots/domain/robot_model.dart';
import 'package:agvnexus/features/robots/presentation/robots_controller.dart';
import 'package:agvnexus/features/telemetry/domain/telemetry_model.dart';
import 'package:agvnexus/features/telemetry/presentation/telemetry_controller.dart';
import 'package:agvnexus/core/widgets/status_pill.dart';

class _MockSelectedRobotIdNotifier extends SelectedRobotIdNotifier {
  final String initialId;
  _MockSelectedRobotIdNotifier(this.initialId);

  @override
  String? build() => initialId;
}

void main() {
  group('DigitalTwinScreen Phase 4 Tests', () {
    final testRobot = RobotModel(
      id: 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01',
      name: 'Titan-01',
      modelType: 'Differential AGV',
      mode: AgvOperatingMode.navigating,
      batteryPercent: 94.5,
      batteryVoltage: 25.4,
      isCharging: false,
      linearVelocity: 0.25,
      angularVelocity: 0.05,
      poseX: 2.50,
      poseY: 3.00,
      poseYaw: 0.785, // ~45 deg
      localizationConfidence: 0.98,
      activeMissionId: 'sim-mission-01',
      lastHeartbeat: DateTime.now(),
      ipAddress: '192.168.1.101',
      rosDomainId: 42,
    );

    final testTelemetry = TelemetryModel(
      robotId: testRobot.id,
      timestamp: DateTime.now(),
      source: 'simulated',
      connectionState: 'connected',
      dataFreshness: 'fresh',
      positionX: 3.12,
      positionY: 4.56,
      positionZ: 0.0,
      yaw: 1.5708, // 90 deg (pi/2)
      linearVelocity: 0.32,
      angularVelocity: 0.0,
      batteryPercent: 91.2,
      batteryVoltage: 24.8,
      operatingState: 'navigating',
      activeMissionId: 'mission-alpha-42',
    );

    testWidgets('Renders 3D Digital Twin screen with Phase 4 banner and controls',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedRobotIdProvider.overrideWith(
              () => _MockSelectedRobotIdNotifier(testRobot.id),
            ),
            robotsStreamProvider.overrideWith(
              (ref) => Stream.value([testRobot]),
            ),
            liveTelemetryStreamProvider.overrideWith(
              (ref) => Stream.value(testTelemetry),
            ),
          ],
          child: const MaterialApp(
            home: DigitalTwinScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & banner
      expect(find.textContaining('3D DIGITAL TWIN'), findsWidgets);
      expect(find.text('3D WEBGL'), findsOneWidget);
      expect(find.text('2D FAILSAFE'), findsOneWidget);

      // Verify live telemetry matrix
      expect(find.text('3.12 m'), findsOneWidget); // X Position
      expect(find.text('4.56 m'), findsOneWidget); // Y Position
      expect(find.text('90.0°'), findsOneWidget);  // Yaw heading
      expect(find.text('0.32 m/s'), findsOneWidget); // Linear velocity
      expect(find.text('91.2%'), findsOneWidget); // Battery
      expect(find.text('FRESH (5Hz Stream)'), findsOneWidget);
    });

    testWidgets('Toggles view mode between 3D WebGL and 2D Failsafe painter',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedRobotIdProvider.overrideWith(
              () => _MockSelectedRobotIdNotifier(testRobot.id),
            ),
            robotsStreamProvider.overrideWith(
              (ref) => Stream.value([testRobot]),
            ),
            liveTelemetryStreamProvider.overrideWith(
              (ref) => Stream.value(testTelemetry),
            ),
          ],
          child: const MaterialApp(
            home: DigitalTwinScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 2D FAILSAFE button
      await tester.tap(find.text('2D FAILSAFE'));
      await tester.pumpAndSettle();

      // Verify 2D HUD label & layers card are present
      expect(find.text('PERSPECTIVE: 2.5D ISOMETRIC'), findsOneWidget);
      expect(find.text('Ground Metric Grid (38x24m)'), findsOneWidget);
      expect(find.text('Factory Stations & Docks'), findsOneWidget);
      expect(find.text('2D Planar LiDAR Fan (0.54m)'), findsOneWidget);

      // Tap 3D WEBGL button to switch back
      await tester.tap(find.text('3D WEBGL'));
      await tester.pumpAndSettle();

      expect(find.text('THREE.JS WEBGL DIGITAL TWIN'), findsOneWidget);
    });

    test('IsometricViewportPainter triggers repaint when pose updates', () {
      final painter1 = IsometricViewportPainter(
        pitch: 0.45,
        yaw: 0.65,
        zoom: 1.0,
        robotPoseX: 2.5,
        robotPoseY: 3.0,
        robotYaw: 0.0,
      );

      final painter2 = IsometricViewportPainter(
        pitch: 0.45,
        yaw: 0.65,
        zoom: 1.0,
        robotPoseX: 2.8, // updated X
        robotPoseY: 3.0,
        robotYaw: 0.0,
      );

      expect(painter2.shouldRepaint(painter1), isTrue);

      final painterIdentical = IsometricViewportPainter(
        pitch: 0.45,
        yaw: 0.65,
        zoom: 1.0,
        robotPoseX: 2.5,
        robotPoseY: 3.0,
        robotYaw: 0.0,
      );

      expect(painterIdentical.shouldRepaint(painter1), isFalse);
    });
  });
}
