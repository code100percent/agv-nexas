import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/config/constants.dart';
import '../../../../core/widgets/industrial_card.dart';

class OperationalEventItem {
  final DateTime timestamp;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;

  const OperationalEventItem({
    required this.timestamp,
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

class OperationalEventsList extends StatelessWidget {
  const OperationalEventsList({super.key});

  static final List<OperationalEventItem> sampleEvents = [
    OperationalEventItem(
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      title: 'Titan-01 waypoint passed',
      detail: 'Arrived at corridor junction WP-04 [nav2_costmap cleared]',
      icon: Icons.check_circle_outline_rounded,
      color: AppColors.primary,
    ),
    OperationalEventItem(
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      title: 'Atlas-02 auto-dock engaged',
      detail: 'Connected to Dock Station 01 charging contacts (27.2V)',
      icon: Icons.battery_charging_full_rounded,
      color: AppColors.success,
    ),
    OperationalEventItem(
      timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
      title: 'Mission MSN-1042 dispatched',
      detail: 'Payload pickup authorized for Warehouse Bay A',
      icon: Icons.assignment_turned_in_outlined,
      color: AppColors.secondary,
    ),
    OperationalEventItem(
      timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
      title: 'Hermes-04 LiDAR obstruction logged',
      detail: 'Optical window reflectance anomaly on front SICK/Hokuyo scanner',
      icon: Icons.warning_amber_rounded,
      color: AppColors.error,
    ),
    OperationalEventItem(
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      title: 'Mission MSN-1041 completed',
      detail: 'Delivered wiring harnesses to Assembly Line 4 on schedule',
      icon: Icons.done_all_rounded,
      color: AppColors.success,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');

    return IndustrialCard(
      title: 'OPERATIONAL EVENT AUDIT LOG',
      subtitle: 'Deterministic audit events for shift verification',
      icon: Icons.history_rounded,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sampleEvents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final event = sampleEvents[index];

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(event.icon, size: 16, color: event.color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeFormat.format(event.timestamp),
                            style: AppTypography.coordinateLabel.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(event.detail, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
