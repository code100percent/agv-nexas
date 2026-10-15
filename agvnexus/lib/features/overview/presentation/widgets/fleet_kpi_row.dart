import 'package:flutter/material.dart';
import '../../../../core/widgets/metric_tile.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../robots/domain/robot_model.dart';
import '../../../missions/domain/mission_model.dart';

/// Responsive KPI row summarizing fleet operational readiness and mission metrics.
class FleetKpiRow extends StatelessWidget {
  final List<RobotModel> robots;
  final List<MissionModel> missions;

  const FleetKpiRow({super.key, required this.robots, required this.missions});

  @override
  Widget build(BuildContext context) {
    final totalRobots = robots.length;
    final activeRobots = robots
        .where(
          (r) =>
              r.mode != AgvOperatingMode.offline &&
              r.mode != AgvOperatingMode.fault,
        )
        .length;
    final activeMissions = missions.where((m) => m.isActive).length;
    final completedMissions = missions
        .where((m) => m.status == MissionStatus.completed)
        .length;
    final activeFaultsCount = robots.fold<int>(
      0,
      (sum, r) => sum + r.activeFaults.length,
    );

    final avgBattery = robots.isEmpty
        ? 0.0
        : robots.fold<double>(0.0, (sum, r) => sum + r.batteryPercent) /
              robots.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 600
            ? 2
            : constraints.maxWidth < 1100
            ? 3
            : 5;

        final items = [
          MetricTile(
            label: 'Fleet Availability',
            value: '$activeRobots / $totalRobots',
            unit: 'AMRs',
            icon: Icons.precision_manufacturing_rounded,
            delta: '+12%',
            isPositiveDelta: true,
            caption: 'Online in zone',
            accentColor: AppColors.primary,
          ),
          MetricTile(
            label: 'Active Missions',
            value: '$activeMissions',
            unit: 'in queue',
            icon: Icons.alt_route_rounded,
            caption: '$completedMissions completed today',
            accentColor: AppColors.secondary,
          ),
          MetricTile(
            label: 'Fleet Battery Avg',
            value: avgBattery.toStringAsFixed(1),
            unit: '%',
            icon: Icons.battery_charging_full_rounded,
            caption: '1 robot charging',
            accentColor: AppColors.success,
          ),
          MetricTile(
            label: 'Operational Faults',
            value: '$activeFaultsCount',
            unit: 'alerts',
            icon: Icons.warning_amber_rounded,
            caption: activeFaultsCount > 0
                ? '1 sensor obstruction'
                : 'All nominal',
            accentColor: activeFaultsCount > 0
                ? AppColors.error
                : AppColors.success,
          ),
          MetricTile(
            label: 'Fleet Travelled',
            value: '42.8',
            unit: 'km',
            icon: Icons.speed_rounded,
            delta: '+3.4km',
            isPositiveDelta: true,
            caption: 'Cumulative shift distance',
            accentColor: AppColors.info,
          ),
        ];

        final ratio = constraints.maxWidth < 450
            ? 1.18
            : constraints.maxWidth < 600
            ? 1.28
            : constraints.maxWidth < 1100
            ? 1.45
            : 1.6;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: ratio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }
}
