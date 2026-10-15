import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// High-performance 2.5D Isometric Viewport Painter.
/// Serves as the primary failsafe rendering engine when WebGL is uninitialized or on low-end hardware.
class IsometricViewportPainter extends CustomPainter {
  final double pitch;
  final double yaw;
  final double zoom;
  final double robotPoseX;
  final double robotPoseY;
  final double robotYaw;
  final bool showGrid;
  final bool showStations;
  final bool showLidar;
  final bool showRoutes;

  IsometricViewportPainter({
    required this.pitch,
    required this.yaw,
    this.zoom = 1.0,
    required this.robotPoseX,
    required this.robotPoseY,
    required this.robotYaw,
    this.showGrid = true,
    this.showStations = true,
    this.showLidar = true,
    this.showRoutes = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final pxPerMeter = 14.0 * zoom;

    // Isometric 3D to 2D projection function
    Offset project(double wx, double wy, double wz) {
      final rotX = wx * cos(yaw) - wy * sin(yaw);
      final rotY = wx * sin(yaw) + wy * cos(yaw);
      final isoX = center.dx + rotX * pxPerMeter;
      final isoY = center.dy + (rotY * sin(pitch) - wz * cos(pitch)) * pxPerMeter;
      return Offset(isoX, isoY);
    }

    // 1. Draw Factory Floor Grid (38m x 24m)
    if (showGrid) {
      final minorGridPaint = Paint()
        ..color = AppColors.borderSubtle.withAlpha(80)
        ..strokeWidth = 1.0;
      final majorGridPaint = Paint()
        ..color = AppColors.borderSubtle
        ..strokeWidth = 1.5;

      const halfW = 19.0;
      const halfH = 12.0;

      for (double x = -halfW; x <= halfW; x += 1.0) {
        final isMajor = (x % 5.0).abs() < 0.01;
        canvas.drawLine(
          project(x, -halfH, 0),
          project(x, halfH, 0),
          isMajor ? majorGridPaint : minorGridPaint,
        );
      }
      for (double y = -halfH; y <= halfH; y += 1.0) {
        final isMajor = (y % 5.0).abs() < 0.01;
        canvas.drawLine(
          project(-halfW, y, 0),
          project(halfW, y, 0),
          isMajor ? majorGridPaint : minorGridPaint,
        );
      }
    }

    // 2. Draw Storage Racks & Obstacles (from factory_arenas2.sdf)
    _drawRacks(canvas, project);

    // 3. Draw Stations & Waypoints
    if (showStations) {
      _drawStations(canvas, project);
    }

    // 4. Draw Mission Transport Corridor Route
    if (showRoutes) {
      _drawMissionRoute(canvas, project);
    }

    // 5. Draw Differential-Drive Robot (URDF dimensions)
    _drawRobotChassis(canvas, project);

    // 6. Draw 2D Planar LiDAR Sensor Sweep
    if (showLidar) {
      _drawLidarFan(canvas, project);
    }
  }

  void _drawRacks(Canvas canvas, Offset Function(double, double, double) project) {
    final rackPaint = Paint()
      ..color = const Color(0xFF1E3A8A).withAlpha(180)
      ..style = PaintingStyle.fill;
    final rackBorder = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rackPositions = [
      [-5.0, -4.2, 2.8, 0.9, 2.5],
      [3.0, -4.2, 2.8, 0.9, 2.5],
      [11.0, -4.2, 2.8, 0.9, 2.5],
    ];

    for (final r in rackPositions) {
      final rx = r[0];
      final ry = r[1];
      final rw = r[2] / 2;
      final rd = r[3] / 2;
      final rh = r[4];

      final p1 = project(rx - rw, ry - rd, rh);
      final p2 = project(rx + rw, ry - rd, rh);
      final p3 = project(rx + rw, ry + rd, rh);
      final p4 = project(rx - rw, ry + rd, rh);

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..lineTo(p4.dx, p4.dy)
        ..close();

      canvas.drawPath(path, rackPaint);
      canvas.drawPath(path, rackBorder);

      // Support pillars to ground
      canvas.drawLine(project(rx - rw, ry - rd, 0), p1, rackBorder);
      canvas.drawLine(project(rx + rw, ry - rd, 0), p2, rackBorder);
      canvas.drawLine(project(rx + rw, ry + rd, 0), p3, rackBorder);
      canvas.drawLine(project(rx - rw, ry + rd, 0), p4, rackBorder);
    }
  }

  void _drawStations(Canvas canvas, Offset Function(double, double, double) project) {
    final stations = [
      {'name': 'Bay A', 'x': -10.0, 'y': -4.0, 'color': AppColors.success},
      {'name': 'Line 4', 'x': 8.0, 'y': 4.0, 'color': AppColors.primary},
      {'name': 'Dock 01', 'x': -14.0, 'y': -8.0, 'color': AppColors.warning},
      {'name': 'QC 2', 'x': 2.0, 'y': 8.0, 'color': const Color(0xFF06B6D4)},
    ];

    for (final stn in stations) {
      final sx = stn['x'] as double;
      final sy = stn['y'] as double;
      final color = stn['color'] as Color;

      // Ground Target Disc
      final groundPos = project(sx, sy, 0);
      final padPaint = Paint()
        ..color = color.withAlpha(60)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(groundPos, 12.0 * zoom, padPaint);

      // Vertical holographic beacon
      final beaconTop = project(sx, sy, 2.2);
      final beaconPaint = Paint()
        ..color = color.withAlpha(160)
        ..strokeWidth = 1.5;
      canvas.drawLine(groundPos, beaconTop, beaconPaint);

      // Diamond marker head
      final dPaint = Paint()..color = color;
      final dPath = Path()
        ..moveTo(beaconTop.dx, beaconTop.dy - 6)
        ..lineTo(beaconTop.dx + 5, beaconTop.dy)
        ..lineTo(beaconTop.dx, beaconTop.dy + 6)
        ..lineTo(beaconTop.dx - 5, beaconTop.dy)
        ..close();
      canvas.drawPath(dPath, dPaint);
    }
  }

  void _drawMissionRoute(Canvas canvas, Offset Function(double, double, double) project) {
    final routePaint = Paint()
      ..color = AppColors.primary.withAlpha(180)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final waypoints = [
      project(-10.0, -4.0, 0.05),
      project(-4.0, -4.0, 0.05),
      project(0.0, 0.0, 0.05),
      project(4.0, 2.0, 0.05),
      project(8.0, 4.0, 0.05),
    ];

    final path = Path()..moveTo(waypoints.first.dx, waypoints.first.dy);
    for (int i = 1; i < waypoints.length; i++) {
      path.lineTo(waypoints[i].dx, waypoints[i].dy);
    }
    canvas.drawPath(path, routePaint);
  }

  void _drawRobotChassis(Canvas canvas, Offset Function(double, double, double) project) {
    // Relative robot coordinates
    final rx = robotPoseX - 12.0;
    final ry = robotPoseY - 6.0;

    // Base Box Chassis (0.395m x 0.279m x 0.015m at z=0.05)
    final boxPaint = Paint()
      ..color = AppColors.primary.withAlpha(50)
      ..style = PaintingStyle.fill;
    final boxBorder = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final p1 = project(rx - 0.4, ry - 0.28, 0.05);
    final p2 = project(rx + 0.4, ry - 0.28, 0.05);
    final p3 = project(rx + 0.4, ry + 0.28, 0.05);
    final p4 = project(rx - 0.4, ry + 0.28, 0.05);

    final p1Top = project(rx - 0.4, ry - 0.28, 0.52);
    final p2Top = project(rx + 0.4, ry - 0.28, 0.52);
    final p3Top = project(rx + 0.4, ry + 0.28, 0.52);
    final p4Top = project(rx - 0.4, ry + 0.28, 0.52);

    final topPath = Path()
      ..moveTo(p1Top.dx, p1Top.dy)
      ..lineTo(p2Top.dx, p2Top.dy)
      ..lineTo(p3Top.dx, p3Top.dy)
      ..lineTo(p4Top.dx, p4Top.dy)
      ..close();

    canvas.drawPath(topPath, boxPaint);
    canvas.drawPath(topPath, boxBorder);

    // Pillars
    canvas.drawLine(p1, p1Top, boxBorder);
    canvas.drawLine(p2, p2Top, boxBorder);
    canvas.drawLine(p3, p3Top, boxBorder);
    canvas.drawLine(p4, p4Top, boxBorder);

    // Forward Heading Vector
    final hTip = project(
      rx + 0.9 * cos(robotYaw),
      ry + 0.9 * sin(robotYaw),
      0.28,
    );
    final hBase = project(rx, ry, 0.28);
    canvas.drawLine(
      hBase,
      hTip,
      Paint()
        ..color = AppColors.deepBurgundy
        ..strokeWidth = 3.0,
    );

    // Ground Selection Halo
    final haloCenter = project(rx, ry, 0.01);
    canvas.drawCircle(
      haloCenter,
      14.0 * zoom,
      Paint()
        ..color = AppColors.primary.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawLidarFan(Canvas canvas, Offset Function(double, double, double) project) {
    final rx = robotPoseX - 12.0;
    final ry = robotPoseY - 6.0;
    const lidarElevation = 0.54;

    final lidarPaint = Paint()
      ..color = AppColors.primary.withAlpha(20)
      ..style = PaintingStyle.fill;
    final arcPaint = Paint()
      ..color = AppColors.primary.withAlpha(90)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = project(rx, ry, lidarElevation);
    final fanPath = Path()..moveTo(center.dx, center.dy);

    const sweepAngle = pi * 1.5;
    const startAngle = -sweepAngle / 2;
    const steps = 16;

    for (int i = 0; i <= steps; i++) {
      final angle = robotYaw + startAngle + (i / steps) * sweepAngle;
      final range = 3.5;
      final pt = project(
        rx + range * cos(angle),
        ry + range * sin(angle),
        lidarElevation,
      );
      fanPath.lineTo(pt.dx, pt.dy);
    }
    fanPath.close();

    canvas.drawPath(fanPath, lidarPaint);
    canvas.drawPath(fanPath, arcPaint);
  }

  @override
  bool shouldRepaint(covariant IsometricViewportPainter oldDelegate) {
    return oldDelegate.pitch != pitch ||
        oldDelegate.yaw != yaw ||
        oldDelegate.zoom != zoom ||
        oldDelegate.robotPoseX != robotPoseX ||
        oldDelegate.robotPoseY != robotPoseY ||
        oldDelegate.robotYaw != robotYaw ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.showStations != showStations ||
        oldDelegate.showLidar != showLidar ||
        oldDelegate.showRoutes != showRoutes;
  }
}
