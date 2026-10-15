import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/config/constants.dart';
import '../../../core/widgets/connection_badge.dart';
import '../../../core/network/connection_state.dart';
import '../../../core/widgets/state_views.dart';
import '../../robots/presentation/robots_controller.dart';
import '../../robots/domain/robot_model.dart';
import '../../../core/config/supabase_config.dart';
import '../data/mock_map_repository.dart';
import '../data/supabase_map_repository.dart';
import '../domain/map_model.dart';
import '../domain/map_repository.dart';
import 'widgets/occupancy_grid_painter.dart';

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  final client = SupabaseConfig.client;
  if (client != null) {
    return SupabaseMapRepository(client);
  }
  return MockMapRepository();
});

final activeMapFutureProvider = FutureProvider<FactoryMapModel>((ref) {
  return ref.watch(mapRepositoryProvider).getActiveMap();
});

class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key});

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  final TransformationController _transformController =
      TransformationController();
  bool _showGrid = true;
  bool _showStations = true;
  bool _showLidar = true;
  bool _showTrajectory = true;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final mapAsync = ref.watch(activeMapFutureProvider);
    final robotsAsync = ref.watch(robotsStreamProvider);
    final selectedRobot = ref.watch(selectedRobotProvider);
    final selectedRobotId = ref.watch(selectedRobotIdProvider);

    return Scaffold(
      backgroundColor: AppColors.mapGridBackground,
      body: Column(
        children: [
          // Simulated/Gateway Active Compliance Banner
          const SimulatedBanner(
            note:
                '2D OCCUPANCY GRID • ROBOTICS GATEWAY & 2D OCCUPANCY MAP ACTIVE',
          ),


          // Map Control Bar (Responsive layout)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 920;

                final chips = [
                  FilterChip(
                    label: const Text('GRID'),
                    selected: _showGrid,
                    onSelected: (v) => setState(() => _showGrid = v),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('STATIONS'),
                    selected: _showStations,
                    onSelected: (v) => setState(() => _showStations = v),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('LIDAR'),
                    selected: _showLidar,
                    onSelected: (v) => setState(() => _showLidar = v),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('TRAJECTORY'),
                    selected: _showTrajectory,
                    onSelected: (v) => setState(() => _showTrajectory = v),
                  ),
                ];

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '2D OCCUPANCY GRID',
                              style: AppTypography.titleMedium.copyWith(
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const ConnectionBadge(
                            status: ConnectionStatus.simulated,
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.center_focus_strong_rounded,
                              size: 18,
                            ),
                            tooltip: 'Reset Map View',
                            onPressed: _resetZoom,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: chips),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    const Icon(
                      Icons.map_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'METRIC OCCUPANCY GRID',
                        style: AppTypography.titleMedium.copyWith(
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const ConnectionBadge(status: ConnectionStatus.simulated),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...chips,
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(
                                Icons.center_focus_strong_rounded,
                                size: 20,
                              ),
                              tooltip: 'Reset Map View',
                              onPressed: _resetZoom,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );

              },
            ),
          ),

          // Map Canvas Workspace
          Expanded(
            child: mapAsync.when(
              loading: () => const LoadingView(
                message: 'Loading factory occupancy grid...',
              ),
              error: (err, _) => ErrorStateView(
                title: 'Failed to load factory map',
                message: err.toString(),
                onRetry: () => ref.refresh(activeMapFutureProvider),
              ),
              data: (map) {
                final robots = robotsAsync.maybeWhen(
                  data: (list) => list,
                  orElse: () => <RobotModel>[],
                );

                return Stack(
                  children: [
                    // Interactive Canvas with Pan & Zoom
                    InteractiveViewer(
                      transformationController: _transformController,
                      boundaryMargin: const EdgeInsets.all(300),
                      minScale: 0.4,
                      maxScale: 3.5,
                      child: Center(
                        child: CustomPaint(
                          size: Size(
                            map.widthMeters * 30.0,
                            map.heightMeters * 30.0,
                          ),
                          painter: OccupancyGridPainter(
                            map: map,
                            robots: robots,
                            selectedRobotId: selectedRobotId,
                            showGrid: _showGrid,
                            showStations: _showStations,
                            showLidar: _showLidar,
                            showTrajectory: _showTrajectory,
                            scale: 30.0,
                          ),
                        ),
                      ),
                    ),

                    // Top Left Active Fleet Switcher
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withAlpha(230),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusSm,
                          ),
                          border: Border.all(color: AppColors.borderMedium),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ROBOT:',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ...robots.map((r) {
                              final isSelected = r.id == selectedRobotId;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  onTap: () {
                                    ref
                                        .read(selectedRobotIdProvider.notifier)
                                        .select(r.id);
                                  },
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusXs,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withAlpha(40)
                                          : AppColors.surfaceRaised,
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.radiusXs,
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.borderSubtle,
                                      ),
                                    ),
                                    child: Text(
                                      r.name,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Right Telemetry Pose Readout HUD
                    if (selectedRobot != null)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withAlpha(245),
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusMd,
                              ),
                              border: Border.all(color: AppColors.borderSubtle),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1830231F),
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        selectedRobot.name.toUpperCase(),
                                        style: AppTypography.labelLarge
                                            .copyWith(color: AppColors.primary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '[${selectedRobot.mode.displayName}]',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: selectedRobot.mode.color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _telemetryChip(
                                      'X',
                                      '${selectedRobot.poseX.toStringAsFixed(1)}m',
                                    ),
                                    _telemetryChip(
                                      'Y',
                                      '${selectedRobot.poseY.toStringAsFixed(1)}m',
                                    ),
                                    _telemetryChip(
                                      'θ',
                                      '${(selectedRobot.poseYaw * 180 / 3.14159).toStringAsFixed(0)}°',
                                    ),
                                    _telemetryChip(
                                      'VEL',
                                      '${selectedRobot.linearVelocity.toStringAsFixed(1)}m/s',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'MAP: ${map.name} (${map.widthMeters.toInt()}m × ${map.heightMeters.toInt()}m)',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 9.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _telemetryChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppConstants.radiusXs),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: AppTypography.coordinateLabel),
          Text(value, style: AppTypography.telemetryCompact),
        ],
      ),
    );
  }
}
