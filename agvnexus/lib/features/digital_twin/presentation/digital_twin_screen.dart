import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/config/constants.dart';
import '../../../core/widgets/connection_badge.dart';
import '../../../core/network/connection_state.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/industrial_card.dart';
import '../../robots/presentation/robots_controller.dart';
import '../../telemetry/presentation/telemetry_controller.dart';
import 'widgets/isometric_viewport_painter.dart';
import 'widgets/web_twin_view.dart';

enum _TwinViewMode { threeD, twoD }

class DigitalTwinScreen extends ConsumerStatefulWidget {
  const DigitalTwinScreen({super.key});

  @override
  ConsumerState<DigitalTwinScreen> createState() => _DigitalTwinScreenState();
}

class _DigitalTwinScreenState extends ConsumerState<DigitalTwinScreen> {
  _TwinViewMode _viewMode = _TwinViewMode.threeD;

  // 2D/2.5D Camera Orbit Parameters
  double _pitch = 0.45;
  double _yaw = 0.65;
  double _zoom = 1.0;

  // Layer Visibility
  bool _showGrid = true;
  bool _showStations = true;
  bool _showLidar = true;
  bool _showRoutes = true;

  @override
  Widget build(BuildContext context) {
    final robot = ref.watch(selectedRobotProvider);
    final selectedRobotId = ref.watch(selectedRobotIdProvider);
    final robotsAsync = ref.watch(robotsStreamProvider);
    final telemetryAsync = ref.watch(liveTelemetryStreamProvider);

    // Prioritize live WebSocket telemetry snapshot, falling back to database model
    final liveTelem = telemetryAsync.asData?.value;
    final posX = liveTelem?.positionX ?? robot?.poseX ?? 2.5;
    final posY = liveTelem?.positionY ?? robot?.poseY ?? 3.0;
    final posZ = liveTelem?.positionZ ?? 0.0;
    final yaw = liveTelem?.yaw ?? robot?.poseYaw ?? 0.0;
    final linearVel = liveTelem?.linearVelocity ?? 0.0;
    final angularVel = liveTelem?.angularVelocity ?? 0.0;
    final battery = liveTelem?.batteryPercent ?? robot?.batteryPercent ?? 94.5;
    final isStale = liveTelem?.dataFreshness == 'stale';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const SimulatedBanner(
            note:
                '3D DIGITAL TWIN & SPATIAL POSE • THREE.JS WEBGL RENDERER & 2D FAILSAFE TACTICAL MAP ACTIVE',
          ),


          // Responsive Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 880;

                final viewModeSelector = SegmentedButton<_TwinViewMode>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.mapGridBackground,
                    selectedBackgroundColor: AppColors.primary.withAlpha(50),
                    selectedForegroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: _TwinViewMode.threeD,
                      label: Text('3D WEBGL'),
                      icon: Icon(Icons.view_in_ar_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: _TwinViewMode.twoD,
                      label: Text('2D FAILSAFE'),
                      icon: Icon(Icons.layers_outlined, size: 16),
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (set) {
                    setState(() => _viewMode = set.first);
                  },
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.precision_manufacturing_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '3D DIGITAL TWIN',
                              style: AppTypography.titleMedium.copyWith(
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ConnectionBadge(
                            status: isStale
                                ? ConnectionStatus.disconnected
                                : ConnectionStatus.simulated,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      viewModeSelector,
                    ],
                  );
                }

                return Row(
                  children: [
                    const Icon(
                      Icons.precision_manufacturing_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        '3D DIGITAL TWIN & SPATIAL POSE',
                        style: AppTypography.titleMedium.copyWith(
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ConnectionBadge(
                      status: isStale
                          ? ConnectionStatus.disconnected
                          : ConnectionStatus.simulated,
                    ),
                    const Spacer(),
                    viewModeSelector,
                  ],
                );

              },
            ),
          ),

          // Main Viewport & Telemetry Workspace
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 880;

                final viewportWidget = Container(
                  height: isWide ? null : 380,
                  decoration: BoxDecoration(
                    color: AppColors.mapGridBackground,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Viewport Body (3D WebGL or 2D Failsafe)
                      Positioned.fill(
                        child: _viewMode == _TwinViewMode.threeD
                            ? WebTwinView(
                                robotId: selectedRobotId ?? 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01',
                                onSwitchTo2D: () => setState(() => _viewMode = _TwinViewMode.twoD),
                              )
                            : GestureDetector(
                                onPanUpdate: (details) {
                                  setState(() {
                                    _yaw += details.delta.dx * 0.005;
                                    _pitch = (_pitch - details.delta.dy * 0.005).clamp(0.1, 1.2);
                                  });
                                },
                                child: CustomPaint(
                                  size: Size.infinite,
                                  painter: IsometricViewportPainter(
                                    pitch: _pitch,
                                    yaw: _yaw,
                                    zoom: _zoom,
                                    robotPoseX: posX,
                                    robotPoseY: posY,
                                    robotYaw: yaw,
                                    showGrid: _showGrid,
                                    showStations: _showStations,
                                    showLidar: _showLidar,
                                    showRoutes: _showRoutes,
                                  ),
                                ),
                              ),
                      ),

                      // Top-left HUD Info Badge
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withAlpha(240),
                            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _viewMode == _TwinViewMode.threeD
                                        ? Icons.view_in_ar_rounded
                                        : Icons.videocam_outlined,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _viewMode == _TwinViewMode.threeD
                                        ? 'THREE.JS WEBGL DIGITAL TWIN'
                                        : 'PERSPECTIVE: 2.5D ISOMETRIC',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _viewMode == _TwinViewMode.threeD
                                    ? 'FASTAPI STATIC GATEWAY /viewer'
                                    : 'DRAG TO ORBIT • HIGH-RELIABILITY FAILSAFE',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Controls (Zoom & Reset)
                      if (_viewMode == _TwinViewMode.twoD)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Row(
                            children: [
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  foregroundColor: AppColors.textPrimary,
                                ),
                                onPressed: () => setState(
                                  () => _zoom = (_zoom + 0.15).clamp(0.5, 2.5),
                                ),
                                icon: const Icon(Icons.zoom_in_rounded, size: 18),
                                tooltip: 'Zoom In',
                              ),
                              const SizedBox(width: 6),
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  foregroundColor: AppColors.textPrimary,
                                ),
                                onPressed: () => setState(
                                  () => _zoom = (_zoom - 0.15).clamp(0.5, 2.5),
                                ),
                                icon: const Icon(Icons.zoom_out_rounded, size: 18),
                                tooltip: 'Zoom Out',
                              ),
                              const SizedBox(width: 6),
                              IconButton.filledTonal(
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.surface,
                                  foregroundColor: AppColors.textPrimary,
                                ),
                                onPressed: () => setState(() {
                                  _pitch = 0.45;
                                  _yaw = 0.65;
                                  _zoom = 1.0;
                                }),
                                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                                tooltip: 'Reset Camera',
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );

                final detailsPanel = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Active Entity & Synchronization Card
                    IndustrialCard(
                      title: 'DIGITAL TWIN STATUS',
                      subtitle: 'Spatial Pose Synchronization',
                      icon: Icons.hub_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTIVE AGV ENTITY',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          robotsAsync.maybeWhen(
                            data: (robots) => DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: selectedRobotId,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(
                                  Icons.precision_manufacturing_rounded,
                                  size: 18,
                                ),
                              ),
                              items: robots
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r.id,
                                      child: Text('${r.name} (${r.modelType})'),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  ref.read(selectedRobotIdProvider.notifier).select(v),
                            ),
                            orElse: () => const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: AppColors.borderSubtle),
                          const SizedBox(height: 14),

                          // Real-Time Spatial Pose Matrix
                          _spatialPoseRow(
                            'X Position (REP-103)',
                            '${posX.toStringAsFixed(2)} m',
                          ),
                          _spatialPoseRow(
                            'Y Position (REP-103)',
                            '${posY.toStringAsFixed(2)} m',
                          ),
                          _spatialPoseRow(
                            'Z Elevation',
                            '${posZ.toStringAsFixed(2)} m',
                          ),
                          _spatialPoseRow(
                            'Yaw Heading (θ)',
                            '${(yaw * 180 / pi).toStringAsFixed(1)}°',
                          ),
                          _spatialPoseRow(
                            'Quaternion Qw',
                            cos(yaw / 2).toStringAsFixed(4),
                          ),
                          _spatialPoseRow(
                            'Quaternion Qz',
                            sin(yaw / 2).toStringAsFixed(4),
                          ),
                          _spatialPoseRow(
                            'Linear Velocity',
                            '${linearVel.toStringAsFixed(2)} m/s',
                          ),
                          _spatialPoseRow(
                            'Angular Velocity',
                            '${angularVel.toStringAsFixed(2)} rad/s',
                          ),
                          _spatialPoseRow(
                            'Battery Level',
                            '${battery.toStringAsFixed(1)}%',
                          ),
                          _spatialPoseRow(
                            'Data Freshness',
                            isStale ? 'STALE (>3s)' : 'FRESH (5Hz Stream)',
                            highlightColor: isStale ? AppColors.error : AppColors.success,
                          ),
                          _spatialPoseRow(
                            'Active Mission',
                            liveTelem?.activeMissionId ?? 'None (Idle)',
                          ),
                          _spatialPoseRow(
                            'Kinematic Mesh',
                            'mobile_robot.urdf (URDF-Accurate)',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppConstants.space16),

                    // Layer Toggles (When in 2D Mode)
                    if (_viewMode == _TwinViewMode.twoD) ...[
                      IndustrialCard(
                        title: 'SPATIAL LAYERS',
                        subtitle: 'Viewport rendering layers',
                        icon: Icons.layers_outlined,
                        child: Column(
                          children: [
                            SwitchListTile(
                              dense: true,
                              title: const Text('Ground Metric Grid (38x24m)'),
                              value: _showGrid,
                              onChanged: (v) => setState(() => _showGrid = v),
                            ),
                            SwitchListTile(
                              dense: true,
                              title: const Text('Factory Stations & Docks'),
                              value: _showStations,
                              onChanged: (v) => setState(() => _showStations = v),
                            ),
                            SwitchListTile(
                              dense: true,
                              title: const Text('2D Planar LiDAR Fan (0.54m)'),
                              value: _showLidar,
                              onChanged: (v) => setState(() => _showLidar = v),
                            ),
                            SwitchListTile(
                              dense: true,
                              title: const Text('Mission Transport Corridors'),
                              value: _showRoutes,
                              onChanged: (v) => setState(() => _showRoutes = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.space16),
                    ],

                    // Architecture & Safety Evaluation Note
                    IndustrialCard(
                      title: 'PHASE 4 ARCHITECTURE BOUNDARIES',
                      subtitle: 'Operational guarantees and digital twin contract',
                      icon: Icons.verified_user_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Guaranteed Engineering Principles:',
                            style: AppTypography.titleSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '• 3D Digital Twin runs in dedicated Three.js WebGL container served directly via FastAPI at /viewer.\n'
                            '• Physical robot geometry matches exact measurements from mobile_robot.urdf (0.395m x 0.279m base, 0.35m track).\n'
                            '• LiDAR is planar 2D (sensor_msgs/msg/LaserScan at z=0.54m) — no fabricated 3D point clouds.\n'
                            '• Native Flutter 2D CustomPainter remains the permanent failsafe when WebGL is unavailable or during hardware degradation.',
                            style: AppTypography.bodySmall.copyWith(
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                if (isWide) {
                  return Padding(
                    padding: const EdgeInsets.all(AppConstants.space16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 7, child: viewportWidget),
                        const SizedBox(width: AppConstants.space16),
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(child: detailsPanel),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.space16),
                  child: Column(
                    children: [
                      viewportWidget,
                      const SizedBox(height: AppConstants.space16),
                      detailsPanel,
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _spatialPoseRow(String label, String value, {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: AppTypography.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 6,
            child: Text(
              value,
              style: AppTypography.telemetryCompact.copyWith(
                color: highlightColor,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
