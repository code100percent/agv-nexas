import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/config/constants.dart';
import '../../../core/widgets/connection_badge.dart';
import '../../../core/network/connection_state.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/industrial_card.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../robots/presentation/robots_controller.dart';
import 'telemetry_controller.dart';

class TelemetryScreen extends ConsumerWidget {
  const TelemetryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final robot = ref.watch(selectedRobotProvider);
    final selectedRobotId = ref.watch(selectedRobotIdProvider);
    final robotsAsync = ref.watch(robotsStreamProvider);
    final liveTelemAsync = ref.watch(liveTelemetryStreamProvider);

    final liveTelem = liveTelemAsync.asData?.value;
    final isStreamingLive = liveTelem != null && liveTelem.isFresh;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SimulatedBanner(
            note: isStreamingLive
                ? 'REAL-TIME TELEMETRY BUS: FASTAPI WEBSOCKET (/ws/telemetry) • SOURCE: ${liveTelem.source.toUpperCase()}'
                : 'ROBOTICS GATEWAY: CONNECTING TO FASTAPI WEBSOCKET BUS (/ws/telemetry)...',
          ),

          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 650;
                final dropdown = robotsAsync.maybeWhen(
                  data: (robots) => DropdownButton<String>(
                    value: selectedRobotId,
                    underline: const SizedBox.shrink(),
                    dropdownColor: AppColors.surfaceRaised,
                    items: robots
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(
                              '${r.name} (${r.id.toUpperCase()})',
                              style: AppTypography.titleSmall,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        ref.read(selectedRobotIdProvider.notifier).select(v),
                  ),
                  orElse: () => const SizedBox.shrink(),
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.query_stats_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'TELEMETRY & SENSORS',
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'TARGET AMR:',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          dropdown,
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    const Icon(
                      Icons.query_stats_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'TELEMETRY & SENSOR DIAGNOSTICS',
                      style: AppTypography.titleMedium.copyWith(
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const ConnectionBadge(status: ConnectionStatus.simulated),
                    const Spacer(),
                    dropdown,
                  ],
                );
              },
            ),
          ),

          Expanded(
            child: robot == null
                ? const LoadingView(message: 'Awaiting AMR sensor packet...')
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.space20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // KPI Row
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = constraints.maxWidth < 600
                                ? 2
                                : constraints.maxWidth < 1100
                                ? 3
                                : 5;
                            final ratio = constraints.maxWidth < 450
                                ? 1.18
                                : constraints.maxWidth < 600
                                ? 1.28
                                : constraints.maxWidth < 1100
                                ? 1.45
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
                                  label: 'Linear Speed',
                                  value:
                                      (liveTelem?.linearVelocity ??
                                              robot.linearVelocity)
                                          .toStringAsFixed(2),
                                  unit: 'm/s',
                                  icon: Icons.speed_rounded,
                                  caption: 'Forward drive velocity',
                                  accentColor: AppColors.primary,
                                ),
                                MetricTile(
                                  label: 'Angular Yaw Rate',
                                  value:
                                      (liveTelem?.angularVelocity ??
                                              robot.angularVelocity)
                                          .toStringAsFixed(2),
                                  unit: 'rad/s',
                                  icon: Icons.rotate_right_rounded,
                                  caption: 'Differential steering',
                                  accentColor: AppColors.secondary,
                                ),
                                MetricTile(
                                  label: 'Pack Voltage',
                                  value:
                                      (liveTelem?.batteryVoltage ??
                                              robot.batteryVoltage)
                                          .toStringAsFixed(1),
                                  unit: 'V',
                                  icon: Icons.bolt_rounded,
                                  caption:
                                      '${(liveTelem?.batteryPercent ?? robot.batteryPercent).toStringAsFixed(0)}% SOC',
                                  accentColor: AppColors.success,
                                ),
                                MetricTile(
                                  label: 'Pose Covariance',
                                  value: '0.042',
                                  unit: 'm²',
                                  icon: Icons.radar_rounded,
                                  caption: 'AMCL convergence metric',
                                  accentColor: AppColors.info,
                                ),
                                MetricTile(
                                  label: 'LiDAR Scan Freq',
                                  value: '15.0',
                                  unit: 'Hz',
                                  icon: Icons.sensors_rounded,
                                  caption: '360° 2D Laser Rangefinder',
                                  accentColor: AppColors.primary,
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: AppConstants.space20),

                        // Sensor Diagnostic Panels
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 900;

                            final leftPanel = Column(
                              children: [
                                IndustrialCard(
                                  title: 'DIFFERENTIAL DRIVE MOTOR ACTUATORS',
                                  subtitle: 'Direct wheel odometry feedback',
                                  icon: Icons.settings_input_component_rounded,
                                  child: Column(
                                    children: [
                                      _dataRow(
                                        'Left Wheel Angular Velocity',
                                        '${(robot.linearVelocity / 0.1).toStringAsFixed(2)} rad/s (120 RPM)',
                                      ),
                                      _dataRow(
                                        'Right Wheel Angular Velocity',
                                        '${(robot.linearVelocity / 0.1).toStringAsFixed(2)} rad/s (120 RPM)',
                                      ),
                                      _dataRow(
                                        'Left Motor Inverter Temp',
                                        '38.2 °C (Nominal)',
                                      ),
                                      _dataRow(
                                        'Right Motor Inverter Temp',
                                        '37.8 °C (Nominal)',
                                      ),
                                      _dataRow(
                                        'Drive Gearbox Ratio',
                                        '1:24 Planetary',
                                      ),
                                      _dataRow(
                                        'Brake Solenoid State',
                                        robot.linearVelocity > 0
                                            ? 'RELEASED'
                                            : 'HOLDING',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppConstants.space20),
                                IndustrialCard(
                                  title: 'BATTERY MANAGEMENT SYSTEM (BMS)',
                                  subtitle:
                                      'Lithium iron phosphate (LiFePO4) 8S pack',
                                  icon: Icons.battery_charging_full_rounded,
                                  child: Column(
                                    children: [
                                      _dataRow(
                                        'State of Charge (SOC)',
                                        '${robot.batteryPercent.toStringAsFixed(1)}%',
                                      ),
                                      _dataRow(
                                        'Terminal Voltage',
                                        '${robot.batteryVoltage} V',
                                      ),
                                      _dataRow(
                                        'Discharge Current',
                                        robot.linearVelocity > 0
                                            ? '14.8 A'
                                            : '1.2 A',
                                      ),
                                      _dataRow(
                                        'Cell Voltage Delta (Max-Min)',
                                        '14 mV (Balanced)',
                                      ),
                                      _dataRow(
                                        'BMS Ambient Temperature',
                                        '26.4 °C',
                                      ),
                                      _dataRow(
                                        'Charge Cycle Count',
                                        '142 cycles',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );

                            final rightPanel = Column(
                              children: [
                                IndustrialCard(
                                  title: 'LOCALIZATION & NAV2 STATUS',
                                  subtitle:
                                      'AMCL / TF2 map->odom->base_link transforms',
                                  icon: Icons.gps_fixed_rounded,
                                  child: Column(
                                    children: [
                                      _dataRow(
                                        'Coordinate Frame Target',
                                        'map -> base_link',
                                      ),
                                      _dataRow(
                                        'Estimated X Position',
                                        '${robot.poseX.toStringAsFixed(3)} m',
                                      ),
                                      _dataRow(
                                        'Estimated Y Position',
                                        '${robot.poseY.toStringAsFixed(3)} m',
                                      ),
                                      _dataRow(
                                        'Estimated Heading Yaw',
                                        '${robot.poseYaw.toStringAsFixed(3)} rad (${(robot.poseYaw * 180 / 3.14159).toStringAsFixed(1)}°)',
                                      ),
                                      _dataRow(
                                        'AMCL Particle Count',
                                        '500 particles',
                                      ),
                                      _dataRow(
                                        'Transform Latency',
                                        '8.4 ms (Fresh)',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppConstants.space20),
                                IndustrialCard(
                                  title: 'NETWORK & ROS 2 NODE HEALTH',
                                  subtitle: 'Local robot computer connectivity',
                                  icon: Icons.network_check_rounded,
                                  child: Column(
                                    children: [
                                      _dataRow(
                                        'Robot IPv4 Address',
                                        robot.ipAddress,
                                      ),
                                      _dataRow(
                                        'ROS 2 Domain ID',
                                        '${robot.rosDomainId}',
                                      ),
                                      _dataRow(
                                        'RMW Implementation',
                                        'rmw_cyclonedds_cpp',
                                      ),
                                      _dataRow(
                                        'DDS Discovery Health',
                                        'PEER RECOGNIZED',
                                      ),
                                      _dataRow(
                                        'Heartbeat Timestamp',
                                        robot.lastHeartbeat.toIso8601String(),
                                      ),
                                      _dataRow(
                                        'Hardware Safety Relay',
                                        'ENERGIZED / NORMAL',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );

                            if (isWide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: leftPanel),
                                  const SizedBox(width: AppConstants.space20),
                                  Expanded(child: rightPanel),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  leftPanel,
                                  const SizedBox(height: AppConstants.space20),
                                  rightPanel,
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTypography.bodySmall)),
          const SizedBox(width: 12),
          Text(
            value,
            style: AppTypography.telemetryCompact,
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}
