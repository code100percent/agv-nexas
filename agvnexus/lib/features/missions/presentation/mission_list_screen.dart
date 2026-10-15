import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/config/constants.dart';
import '../../../core/widgets/connection_badge.dart';
import '../../../core/network/connection_state.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/mission_model.dart';
import 'create_mission_dialog.dart';
import 'missions_controller.dart';

class MissionListScreen extends ConsumerWidget {
  const MissionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionsAsync = ref.watch(missionsStreamProvider);
    final currentFilter = ref.watch(missionFilterStatusProvider);
    final filteredMissions = ref.watch(filteredMissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const SimulatedBanner(
            note:
                'MISSION DISPATCH MANAGER (PHASE 3 ACTIVE: FASTAPI MISSION DISPATCH REST API & VALIDATED IDEMPOTENCY).',
          ),

          // Control & Action Bar (Fully responsive to prevent overflow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 980;

                final chips = [
                  FilterChip(
                    label: const Text('ALL'),
                    selected: currentFilter == null,
                    onSelected: (_) => ref
                        .read(missionFilterStatusProvider.notifier)
                        .setFilter(null),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('IN PROGRESS'),
                    selected: currentFilter == MissionStatus.inProgress,
                    onSelected: (v) => ref
                        .read(missionFilterStatusProvider.notifier)
                        .setFilter(v ? MissionStatus.inProgress : null),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('QUEUED'),
                    selected: currentFilter == MissionStatus.queued,
                    onSelected: (v) => ref
                        .read(missionFilterStatusProvider.notifier)
                        .setFilter(v ? MissionStatus.queued : null),
                  ),
                  const SizedBox(width: 6),
                  FilterChip(
                    label: const Text('COMPLETED'),
                    selected: currentFilter == MissionStatus.completed,
                    onSelected: (v) => ref
                        .read(missionFilterStatusProvider.notifier)
                        .setFilter(v ? MissionStatus.completed : null),
                  ),
                ];

                final newMissionBtn = ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const CreateMissionDialog(),
                    );
                  },
                  icon: const Icon(Icons.add_task_rounded, size: 16),
                  label: const Text('NEW MISSION'),
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.alt_route_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'MISSION DISPATCH',
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
                          const SizedBox(width: 8),
                          newMissionBtn,
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
                      Icons.alt_route_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'MISSION DISPATCH QUEUE',
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
                            const SizedBox(width: 16),
                            newMissionBtn,
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Missions List
          Expanded(
            child: missionsAsync.when(
              loading: () =>
                  const LoadingView(message: 'Loading logistics missions...'),
              error: (err, _) => ErrorStateView(
                title: 'Mission Dispatch Query Error',
                message: err.toString(),
                onRetry: () => ref.refresh(missionsStreamProvider),
              ),
              data: (_) {
                if (filteredMissions.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.alt_route_outlined,
                    title: 'No Missions Found',
                    description:
                        'There are currently no active or historical missions matching the selected criteria.',
                    actionLabel: 'DISPATCH MISSION',
                    onAction: () {
                      showDialog(
                        context: context,
                        builder: (_) => const CreateMissionDialog(),
                      );
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppConstants.space16),
                  itemCount: filteredMissions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final mission = filteredMissions[index];
                    return _buildMissionCard(context, ref, mission);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(
    BuildContext context,
    WidgetRef ref,
    MissionModel mission,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C30231F),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mission.priority.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppConstants.radiusXs),
                  border: Border.all(
                    color: mission.priority.color.withAlpha(80),
                  ),
                ),
                child: Text(
                  mission.priority.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: mission.priority.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  mission.id.length > 8
                      ? '${mission.id.substring(0, 8)}...'
                      : mission.id,
                  style: AppTypography.coordinateLabel,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mission.name,
                  style: AppTypography.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mission.status.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppConstants.radiusXs),
                  border: Border.all(color: mission.status.color.withAlpha(80)),
                ),
                child: Text(
                  mission.status.displayName,
                  style: AppTypography.labelSmall.copyWith(
                    color: mission.status.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Route Details (Responsive layout prevents overflow)
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 740;

              final routeWidgets = [
                const Icon(
                  Icons.outbox_rounded,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    mission.sourceStationName,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.move_to_inbox_rounded,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    mission.destinationStationName,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ];

              final payloadAndRobot = [
                const Icon(
                  Icons.scale_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${mission.payloadWeightKg.toInt()} kg',
                  style: AppTypography.telemetryCompact,
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.smart_toy_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    mission.assignedRobotName ?? 'UNASSIGNED',
                    style: AppTypography.telemetryCompact.copyWith(
                      color: mission.assignedRobotName != null
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ];

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: routeWidgets),
                    const SizedBox(height: 6),
                    Row(children: payloadAndRobot),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: routeWidgets,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(mainAxisSize: MainAxisSize.min, children: payloadAndRobot),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // Progress Bar
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: mission.progressPercent / 100.0,
                  backgroundColor: AppColors.surfaceRaised,
                  valueColor: AlwaysStoppedAnimation(mission.status.color),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${mission.progressPercent.toInt()}%',
                style: AppTypography.telemetryCompact,
              ),
              if (mission.isActive) ...[
                const SizedBox(width: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    textStyle: AppTypography.labelSmall,
                  ),
                  onPressed: () {
                    ref
                        .read(missionRepositoryProvider)
                        .cancelMission(mission.id);
                  },
                  child: const Text('CANCEL'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
