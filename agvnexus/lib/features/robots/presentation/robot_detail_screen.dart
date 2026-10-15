import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/config/constants.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/industrial_card.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../../core/widgets/state_views.dart';
import 'robots_controller.dart';
import 'widgets/teleoperation_pad.dart';

class RobotDetailScreen extends ConsumerWidget {
  final String robotId;

  const RobotDetailScreen({super.key, required this.robotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final robotsAsync = ref.watch(robotsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ROBOT TELEMETRY: ${robotId.toUpperCase()}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: robotsAsync.when(
        loading: () =>
            const LoadingView(message: 'Loading AMR telemetry node...'),
        error: (err, _) => ErrorStateView(
          title: 'Failed to read robot data',
          message: err.toString(),
          onRetry: () => ref.refresh(robotsStreamProvider),
        ),
        data: (robots) {
          final robot = robots.where((r) => r.id == robotId).firstOrNull;

          if (robot == null) {
            return EmptyStateView(
              icon: Icons.precision_manufacturing_outlined,
              title: 'Robot Not Found',
              description:
                  'The requested AMR identifier "$robotId" was not found in the fleet catalog.',
              actionLabel: 'BACK TO FLEET',
              onAction: () => context.pop(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 650;
                    final trackButton = ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(selectedRobotIdProvider.notifier)
                            .select(robot.id);
                        context.go('/map');
                      },
                      icon: const Icon(
                        Icons.location_searching_rounded,
                        size: 16,
                      ),
                      label: const Text('TRACK ON MAP'),
                    );

                    if (isCompact) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMd,
                          ),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceRaised,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryGlow,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.precision_manufacturing_rounded,
                                    size: 24,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        robot.name,
                                        style: AppTypography.displayMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      StatusPill(mode: robot.mode),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${robot.modelType} • ROS 2 Domain: ${robot.rosDomainId} • IP: ${robot.ipAddress}',
                              style: AppTypography.bodySmall,
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: trackButton,
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusMd,
                        ),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceRaised,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryGlow,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.precision_manufacturing_rounded,
                              size: 32,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      robot.name,
                                      style: AppTypography.displayMedium,
                                    ),
                                    const SizedBox(width: 12),
                                    StatusPill(mode: robot.mode),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${robot.modelType} • ROS 2 Domain: ${robot.rosDomainId} • IP: ${robot.ipAddress}',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          trackButton,
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppConstants.space20),

                // Primary Vitals Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth < 700 ? 2 : 4;
                    final ratio = constraints.maxWidth < 450
                        ? 1.18
                        : constraints.maxWidth < 700
                        ? 1.28
                        : 1.6;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: cols,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: ratio,
                      children: [
                        MetricTile(
                          label: 'Battery Level',
                          value: robot.batteryPercent.toStringAsFixed(1),
                          unit: '%',
                          icon: Icons.battery_charging_full_rounded,
                          caption: '${robot.batteryVoltage} V nominal',
                          accentColor: robot.isCharging
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        MetricTile(
                          label: 'Linear Velocity',
                          value: robot.linearVelocity.toStringAsFixed(2),
                          unit: 'm/s',
                          icon: Icons.speed_rounded,
                          caption:
                              'Angular: ${robot.angularVelocity.toStringAsFixed(2)} rad/s',
                          accentColor: AppColors.secondary,
                        ),
                        MetricTile(
                          label: 'Map Coordinates',
                          value:
                              '${robot.poseX.toStringAsFixed(1)}, ${robot.poseY.toStringAsFixed(1)}',
                          unit: 'm',
                          icon: Icons.my_location_rounded,
                          caption:
                              'Heading: ${(robot.poseYaw * 180 / 3.14159).toStringAsFixed(1)}°',
                          accentColor: AppColors.primary,
                        ),
                        MetricTile(
                          label: 'AMCL Confidence',
                          value:
                              '${(robot.localizationConfidence * 100).toInt()}',
                          unit: '%',
                          icon: Icons.radar_rounded,
                          caption: 'Covariance threshold OK',
                          accentColor: AppColors.success,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppConstants.space20),

                // Manual / Mobile Teleoperation Pad (Phase 3)
                TeleoperationPad(robotId: robot.id),

                const SizedBox(height: AppConstants.space20),

                // Faults & Controls Section
                IndustrialCard(
                  title: 'SAFETY & EMERGENCY CONTROLS',
                  subtitle: 'Industrial robotics safety command interface',
                  icon: Icons.warning_amber_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (robot.activeFaults.isNotEmpty) ...[
                        Text(
                          'ACTIVE FAULTS & WARNINGS:',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...robot.activeFaults.map(
                          (f) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.errorDim.withAlpha(40),
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusSm,
                              ),
                              border: Border.all(color: AppColors.error),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    f,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    ref
                                        .read(robotRepositoryProvider)
                                        .clearFaults(robot.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Cleared fault: $f'),
                                        backgroundColor: AppColors.primary,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: const Text('CLEAR FAULT'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              ref
                                  .read(robotRepositoryProvider)
                                  .triggerEmergencyStop(robot.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'EMERGENCY STOP DISPATCHED: Standstill command issued to ${robot.name}',
                                  ),
                                  backgroundColor: AppColors.error,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.stop_circle_rounded,
                              size: 18,
                            ),
                            label: const Text('TRIGGER SOFTWARE E-STOP'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              ref
                                  .read(robotRepositoryProvider)
                                  .clearFaults(robot.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'State reset signal dispatched to ${robot.name}',
                                  ),
                                  backgroundColor: AppColors.primary,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('RESET ALL STATE'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Text(
                        'WARNING: In production, software e-stop is a convenience command; physical safety relies strictly on certified hardware estop circuitry.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
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
