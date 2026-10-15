import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/map_model.dart';
import '../../../robots/domain/robot_model.dart';

/// High-performance CustomPainter rendering 2D metric occupancy grid,
/// obstacles, factory stations, differential-drive robot pose, and trajectory.
class OccupancyGridPainter extends CustomPainter {
  final FactoryMapModel map;
  final List<RobotModel> robots;
  final String? selectedRobotId;
  final bool showGrid;
  final bool showStations;
  final bool showLidar;
  final bool showTrajectory;
  final double scale; // Pixels per meter

  OccupancyGridPainter({
    required this.map,
    required this.robots,
    this.selectedRobotId,
    this.showGrid = true,
    this.showStations = true,
    this.showLidar = true,
    this.showTrajectory = true,
    this.scale = 30.0, // 30 pixels = 1 meter
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background Fill
    final bgPaint = Paint()..color = AppColors.mapGridBackground;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Metric Grid (1m minor, 5m major)
    if (showGrid) {
      _drawMetricGrid(canvas, size);
    }

    // 3. Obstacles and Factory Walls
    _drawObstacles(canvas);

    // 4. Stations and Waypoints
    if (showStations) {
      _drawStations(canvas);
    }

    // 5. Active Robot Trajectories
    if (showTrajectory) {
      _drawTrajectories(canvas);
    }

    // 6. Robots with Chassis, Heading, and LiDAR
    _drawRobots(canvas);

    // 7. World Origin Crosshair (0,0) - REP-103 standard (X red, Y green)
    _drawOriginAxes(canvas);
  }

  void _drawMetricGrid(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = AppColors.mapGridMinor
      ..strokeWidth = 1.0;

    final majorPaint = Paint()
      ..color = AppColors.mapGridMajor
      ..strokeWidth = 1.5;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw vertical meter lines
    for (double x = 0; x <= map.widthMeters; x += 1.0) {
      final isMajor = (x % 5.0).abs() < 0.001;
      final px = x * scale;
      canvas.drawLine(
        Offset(px, 0),
        Offset(px, map.heightMeters * scale),
        isMajor ? majorPaint : minorPaint,
      );

      if (isMajor && x > 0) {
        textPainter.text = TextSpan(
          text: '${x.toInt()}m',
          style: const TextStyle(color: AppColors.textDisabled, fontSize: 9),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(px + 2, 4));
      }
    }

    // Draw horizontal meter lines
    for (double y = 0; y <= map.heightMeters; y += 1.0) {
      final isMajor = (y % 5.0).abs() < 0.001;
      final py = y * scale;
      canvas.drawLine(
        Offset(0, py),
        Offset(map.widthMeters * scale, py),
        isMajor ? majorPaint : minorPaint,
      );

      if (isMajor && y > 0) {
        textPainter.text = TextSpan(
          text: '${y.toInt()}m',
          style: const TextStyle(color: AppColors.textDisabled, fontSize: 9),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(4, py + 2));
      }
    }
  }

  void _drawObstacles(Canvas canvas) {
    final obstacleFill = Paint()
      ..color = const Color(0xFF1B222E)
      ..style = PaintingStyle.fill;

    final obstacleBorder = Paint()
      ..color = const Color(0xFF2C394E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final rectData in map.obstacleRects) {
      final rect = Rect.fromLTWH(
        rectData[0] * scale,
        rectData[1] * scale,
        rectData[2] * scale,
        rectData[3] * scale,
      );
      canvas.drawRect(rect, obstacleFill);
      canvas.drawRect(rect, obstacleBorder);
    }
  }

  void _drawStations(Canvas canvas) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final stn in map.stations) {
      final center = Offset(stn.x * scale, stn.y * scale);
      Color stationColor;

      switch (stn.type) {
        case StationType.dock:
          stationColor = AppColors.success;
          break;
        case StationType.pickup:
          stationColor = AppColors.primary;
          break;
        case StationType.delivery:
          stationColor = AppColors.warning;
          break;
        case StationType.waypoint:
          stationColor = AppColors.info;
          break;
      }

      // Station footprint zone
      final zonePaint = Paint()
        ..color = stationColor.withAlpha(25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 0.8 * scale, zonePaint);

      final markerBorder = Paint()
        ..color = stationColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, 6.0, markerBorder);

      // Station Name Label
      textPainter.text = TextSpan(
        text: stn.name,
        style: TextStyle(
          color: stationColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy + 10),
      );
    }
  }

  void _drawTrajectories(Canvas canvas) {
    final trajectoryPaint = Paint()
      ..color = AppColors.mapTrajectory.withAlpha(140)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final robot in robots) {
      if (robot.activeMissionId != null) {
        // Draw waypoint trajectory path
        final path = Path();
        path.moveTo(robot.poseX * scale, robot.poseY * scale);

        // Connect to destination station (Assembly Line 3 at 18.0, 16.0 for Titan-01)
        final destX = 18.0 * scale;
        final destY = 16.0 * scale;
        final midX = (robot.poseX * scale + destX) / 2;

        path.cubicTo(midX, robot.poseY * scale, midX, destY, destX, destY);
        canvas.drawPath(path, trajectoryPaint);
      }
    }
  }

  void _drawRobots(Canvas canvas) {
    for (final robot in robots) {
      final isSelected = robot.id == selectedRobotId;
      final center = Offset(robot.poseX * scale, robot.poseY * scale);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(robot.poseYaw);

      // 1. Simulated 2D LiDAR fan
      if (showLidar && robot.isConnected) {
        final lidarPaint = Paint()
          ..color = AppColors.mapLidarBeam
          ..style = PaintingStyle.fill;

        final lidarArc = Path()
          ..moveTo(0, 0)
          ..arcTo(
            Rect.fromCircle(center: Offset.zero, radius: 4.5 * scale),
            -pi * 0.75,
            pi * 1.5,
            false,
          )
          ..close();
        canvas.drawPath(lidarArc, lidarPaint);
      }

      // 2. Chassis Dimensions (0.9m length, 0.65m width)
      final chassisWidth = 0.65 * scale;
      final chassisLength = 0.90 * scale;
      final chassisRect = Rect.fromCenter(
        center: Offset.zero,
        width: chassisLength,
        height: chassisWidth,
      );

      final chassisFill = Paint()
        ..color = isSelected ? const Color(0xFF1E2C3D) : const Color(0xFF181F2A)
        ..style = PaintingStyle.fill;

      final chassisBorder = Paint()
        ..color = isSelected ? AppColors.primary : AppColors.borderBright
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 1.2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(chassisRect, const Radius.circular(4)),
        chassisFill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(chassisRect, const Radius.circular(4)),
        chassisBorder,
      );

      // 3. Drive Wheels (Left & Right)
      final wheelPaint = Paint()..color = const Color(0xFF475569);
      final wheelLength = 0.3 * scale;
      final wheelThickness = 0.08 * scale;

      // Left wheel (y > 0)
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(0, chassisWidth / 2),
          width: wheelLength,
          height: wheelThickness,
        ),
        wheelPaint,
      );
      // Right wheel (y < 0)
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(0, -chassisWidth / 2),
          width: wheelLength,
          height: wheelThickness,
        ),
        wheelPaint,
      );

      // 4. Heading Forward Vector (X is forward)
      final headingPaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset.zero,
        Offset(chassisLength * 0.75, 0),
        headingPaint,
      );

      // Heading Arrowhead
      final arrowPath = Path()
        ..moveTo(chassisLength * 0.75, 0)
        ..lineTo(chassisLength * 0.60, -4)
        ..lineTo(chassisLength * 0.60, 4)
        ..close();
      canvas.drawPath(arrowPath, Paint()..color = AppColors.primary);

      canvas.restore();

      // 5. Text Label (Non-rotated, centered above robot)
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: '${robot.name} (${robot.batteryPercent.toInt()}%)',
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          backgroundColor: AppColors.background.withAlpha(180),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - chassisWidth - 14,
        ),
      );
    }
  }

  void _drawOriginAxes(Canvas canvas) {
    // ROS REP-103: X forward (red), Y left (green)
    const axisLength = 30.0;

    // X Axis
    final xPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset.zero, const Offset(axisLength, 0), xPaint);

    // Y Axis
    final yPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset.zero, const Offset(0, axisLength), yPaint);

    final originPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset.zero, 3.0, originPaint);
  }

  @override
  bool shouldRepaint(covariant OccupancyGridPainter oldDelegate) {
    return true; // Live telemetry & simulation updates repaint
  }
}
