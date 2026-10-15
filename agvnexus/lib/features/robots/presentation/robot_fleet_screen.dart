import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/config/constants.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/connection_badge.dart';
import '../../../core/network/connection_state.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/robot_model.dart';
import 'robots_controller.dart';

class RobotFleetScreen extends ConsumerStatefulWidget {
  const RobotFleetScreen({super.key});

  @override
  ConsumerState<RobotFleetScreen> createState() => _RobotFleetScreenState();
}

class _RobotFleetScreenState extends ConsumerState<RobotFleetScreen> {
  AgvOperatingMode? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final robotsAsync = ref.watch(robotsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const SimulatedBanner(
            note:
                'FLEET TELEMETRY DIRECTORY (DETERMINISTIC SIMULATION TIER). Live DDS/ROS 2 node integration in Phase 3.',
          ),

          // Action & Filter Bar (Fully responsive to prevent any RenderFlex overflow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 950;

                final chips = [
                  FilterChip(
                    label: const Text('ALL'),
                    selected: _selectedFilter == null,
                    onSelected: (_) => setState(() => _selectedFilter = null),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('NAVIGATING'),
                    selected: _selectedFilter == AgvOperatingMode.navigating,
                    onSelected: (v) => setState(
                      () => _selectedFilter = v
                          ? AgvOperatingMode.navigating
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('CHARGING'),
                    selected: _selectedFilter == AgvOperatingMode.charging,
                    onSelected: (v) => setState(
                      () => _selectedFilter = v
                          ? AgvOperatingMode.charging
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('FAULT'),
                    selected: _selectedFilter == AgvOperatingMode.fault,
                    onSelected: (v) => setState(
                      () => _selectedFilter = v ? AgvOperatingMode.fault : null,
                    ),
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
                            Icons.precision_manufacturing_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AMR FLEET DIRECTORY',
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
                        ],
                      ),
                      const SizedBox(height: 10),
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
                      Icons.precision_manufacturing_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'AUTONOMOUS MOBILE ROBOT FLEET',
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
                        FilterChip(
                          label: const Text('ALL'),
                          selected: _selectedFilter == null,
                          onSelected: (_) =>
                              setState(() => _selectedFilter = null),
                        ),
                        FilterChip(
                          label: const Text('NAVIGATING'),
                          selected:
                              _selectedFilter == AgvOperatingMode.navigating,
                          onSelected: (v) => setState(
                            () => _selectedFilter = v
                                ? AgvOperatingMode.navigating
                                : null,
                          ),
                        ),
                        FilterChip(
                          label: const Text('CHARGING'),
                          selected:
                              _selectedFilter == AgvOperatingMode.charging,
                          onSelected: (v) => setState(
                            () => _selectedFilter = v
                                ? AgvOperatingMode.charging
                                : null,
                          ),
                        ),
                        FilterChip(
                          label: const Text('FAULT'),
                          selected: _selectedFilter == AgvOperatingMode.fault,
                          onSelected: (v) => setState(
                            () => _selectedFilter = v
                                ? AgvOperatingMode.fault
                                : null,
                          ),
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

          // Fleet List
          Expanded(
            child: robotsAsync.when(
              loading: () =>
                  const LoadingView(message: 'Querying robot fleet catalog...'),
              error: (err, _) => ErrorStateView(
                title: 'Fleet Catalog Error',
                message: err.toString(),
                onRetry: () => ref.refresh(robotsStreamProvider),
              ),
              data: (robots) {
                final filtered = _selectedFilter == null
                    ? robots
                    : robots.where((r) => r.mode == _selectedFilter).toList();

                if (filtered.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.precision_manufacturing_outlined,
                    title: 'No Robots In Selected State',
                    description:
                        'No AMRs in the fleet match the currently active filter query.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppConstants.space16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final robot = filtered[index];
                    return _buildRobotCard(context, robot);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRobotCard(BuildContext context, RobotModel robot) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: robot.hasFaults
              ? AppColors.error.withAlpha(120)
              : AppColors.borderSubtle,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C30231F),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Header + Mode
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    border: Border.all(color: AppColors.borderMedium),
                  ),
                  child: const Icon(
                    Icons.precision_manufacturing_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              robot.name,
                              style: AppTypography.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '[${robot.id.toUpperCase()}]',
                            style: AppTypography.coordinateLabel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${robot.modelType} • ROS: ${robot.rosDomainId} • IP: ${robot.ipAddress}',
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill(mode: robot.mode),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(color: AppColors.borderSubtle),
            const SizedBox(height: 14),

            // Row 2: Vitals Bar (Responsive Layout prevents flex overflows)
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 560;

                final batteryWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'BATTERY',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          '${robot.batteryPercent.toStringAsFixed(1)}%',
                          style: AppTypography.telemetryCompact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: robot.batteryPercent / 100.0,
                      backgroundColor: AppColors.surfaceRaised,
                      valueColor: AlwaysStoppedAnimation(
                        robot.batteryPercent > 30
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                );

                final posWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MAP POSITION',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(${robot.poseX.toStringAsFixed(1)}m, ${robot.poseY.toStringAsFixed(1)}m)',
                      style: AppTypography.telemetryCompact,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );

                final velWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VELOCITY',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${robot.linearVelocity.toStringAsFixed(2)} m/s',
                      style: AppTypography.telemetryCompact,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );

                final amclWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AMCL QUALITY',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(robot.localizationConfidence * 100).toInt()}%',
                      style: AppTypography.telemetryCompact.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                );

                if (isCompact) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: batteryWidget),
                          const SizedBox(width: 16),
                          Expanded(child: posWidget),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: velWidget),
                          const SizedBox(width: 16),
                          Expanded(child: amclWidget),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 3, child: batteryWidget),
                    const SizedBox(width: 20),
                    Expanded(flex: 3, child: posWidget),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: velWidget),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: amclWidget),
                  ],
                );
              },
            ),

            if (robot.activeFaults.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.errorDim,
                  borderRadius: BorderRadius.circular(AppConstants.radiusXs),
                  border: Border.all(color: AppColors.error.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        robot.activeFaults.first,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Row 3: Action Buttons (Wrapped to prevent right-edge overflow on mobile)
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(selectedRobotIdProvider.notifier)
                          .select(robot.id);
                      context.go('/map');
                    },
                    icon: const Icon(
                      Icons.location_searching_rounded,
                      size: 14,
                    ),
                    label: const Text('TRACK ON MAP'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/robots/${robot.id}'),
                    icon: const Icon(Icons.query_stats_rounded, size: 14),
                    label: const Text('TELEMETRY'),
                  ),
                  if (robot.mode != AgvOperatingMode.estop)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorDim,
                        foregroundColor: AppColors.error,
                        side: const BorderSide(
                          color: AppColors.error,
                          width: 1,
                        ),
                      ),
                      onPressed: () {
                        ref
                            .read(robotRepositoryProvider)
                            .triggerEmergencyStop(robot.id);
                      },
                      icon: const Icon(Icons.stop_circle_outlined, size: 14),
                      label: const Text('E-STOP'),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(robotRepositoryProvider).clearFaults(robot.id);
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('RESET'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
