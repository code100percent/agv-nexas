import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/widgets/industrial_card.dart';
import '../../../missions/domain/mission_model.dart';

class ActiveMissionStrip extends StatelessWidget {
  final List<MissionModel> activeMissions;
  final VoidCallback? onManageMissions;

  const ActiveMissionStrip({
    super.key,
    required this.activeMissions,
    this.onManageMissions,
  });

  @override
  Widget build(BuildContext context) {
    return IndustrialCard(
      title: 'ACTIVE MISSION DISPATCH',
      subtitle:
          '${activeMissions.length} missions in progress or pending assignment',
      icon: Icons.alt_route_rounded,
      trailing: TextButton.icon(
        onPressed: onManageMissions,
        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
        label: const Text('ALL MISSIONS'),
      ),
      child: activeMissions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No missions currently in transit.',
                  style: AppTypography.bodyMedium,
                ),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeMissions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final mission = activeMissions[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 640;

                      final priorityBadge = Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: mission.priority.color.withAlpha(30),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusXs,
                          ),
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
                      );

                      final robotBadge = Text(
                        mission.assignedRobotName ?? 'UNASSIGNED',
                        style: AppTypography.labelSmall.copyWith(
                          color: mission.assignedRobotName != null
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      );

                      final displayId = mission.id.length > 8
                          ? '${mission.id.substring(0, 8)}...'
                          : mission.id;

                      final routeRow = SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              mission.sourceStationName,
                              style: AppTypography.bodySmall,
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.flag_outlined,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              mission.destinationStationName,
                              style: AppTypography.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${mission.progressPercent.toInt()}%',
                              style: AppTypography.telemetryCompact,
                            ),
                          ],
                        ),
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isCompact) ...[
                            Row(
                              children: [
                                priorityBadge,
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    displayId,
                                    style: AppTypography.coordinateLabel,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(child: robotBadge),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              mission.name,
                              style: AppTypography.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ] else ...[
                            Row(
                              children: [
                                priorityBadge,
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    displayId,
                                    style: AppTypography.coordinateLabel,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    mission.name,
                                    style: AppTypography.titleSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(child: robotBadge),
                              ],
                            ),
                          ],

                          const SizedBox(height: 8),
                          routeRow,
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: mission.progressPercent / 100.0,
                            backgroundColor: AppColors.surfaceOverlay,
                            valueColor: AlwaysStoppedAnimation(
                              mission.status == MissionStatus.inProgress
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
