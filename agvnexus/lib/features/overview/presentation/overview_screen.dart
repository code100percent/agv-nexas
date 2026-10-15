import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/config/constants.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/connection_badge.dart';
import '../../../core/network/connection_state.dart';
import '../../robots/presentation/robots_controller.dart';
import '../../missions/presentation/missions_controller.dart';
import '../../missions/domain/mission_model.dart';
import '../../maps/presentation/live_map_screen.dart';
import '../../maps/presentation/widgets/occupancy_grid_painter.dart';
import 'widgets/fleet_kpi_row.dart';
import 'widgets/active_mission_strip.dart';
import 'widgets/quick_alerts_card.dart';
import 'widgets/operational_events_list.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final robotsAsync = ref.watch(robotsStreamProvider);
    final missionsAsync = ref.watch(missionsStreamProvider);
    final activeMissions = ref.watch(activeMissionsProvider);
    final mapAsync = ref.watch(activeMapFutureProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const SimulatedBanner(
            note:
                'OPERATIONS OVERVIEW • REAL-TIME AMR FLEET MONITORING & DISPATCH ACTIVE',
          ),

          Expanded(
            child: robotsAsync.when(
              loading: () =>
                  const LoadingView(message: 'Querying AMR fleet status...'),
              error: (err, _) => ErrorStateView(
                title: 'Fleet Query Error',
                message: err.toString(),
                onRetry: () => ref.refresh(robotsStreamProvider),
              ),
              data: (robots) {
                final missions = missionsAsync.maybeWhen(
                  data: (m) => m,
                  orElse: () => <MissionModel>[],
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.space20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Context Header
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 600;
                          if (isCompact) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'OPERATIONS OVERVIEW',
                                        style: AppTypography.displayMedium,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const ConnectionBadge(
                                      status: ConnectionStatus.simulated,
                                      compact: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Nexus Plant 1 • Real-time autonomous dispatch & fleet vitals',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            );
                          }
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'OPERATIONS OVERVIEW',
                                      style: AppTypography.displayMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Nexus Plant 1 • Real-time autonomous dispatch & fleet vitals',
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const ConnectionBadge(
                                status: ConnectionStatus.simulated,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: AppConstants.space20),

                      // Fleet KPIs
                      FleetKpiRow(robots: robots, missions: missions),

                      const SizedBox(height: AppConstants.space20),

                      // Responsive Two-Column or Stacked Layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 1024;

                          final leftColumn = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Live Map Quick View Card
                              Container(
                                height: 320,
                                decoration: BoxDecoration(
                                  color: AppColors.mapGridBackground,
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: AppColors.borderSubtle,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  children: [
                                    mapAsync.maybeWhen(
                                      data: (map) => Center(
                                        child: CustomPaint(
                                          size: Size(
                                            map.widthMeters * 18.0,
                                            map.heightMeters * 18.0,
                                          ),
                                          painter: OccupancyGridPainter(
                                            map: map,
                                            robots: robots,
                                            scale: 18.0,
                                            showLidar: true,
                                            showTrajectory: true,
                                          ),
                                        ),
                                      ),
                                      orElse: () => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    // Overlay header
                                    Positioned(
                                      top: 12,
                                      left: 14,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface.withAlpha(
                                            220,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppConstants.radiusXs,
                                          ),
                                          border: Border.all(
                                            color: AppColors.borderMedium,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.radar_rounded,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'LIVE 2D MAP RADAR',
                                              style: AppTypography.labelSmall
                                                  .copyWith(
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 12,
                                      right: 14,
                                      child: ElevatedButton.icon(
                                        onPressed: () => context.go('/map'),
                                        icon: const Icon(
                                          Icons.fullscreen_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('OPEN FULL MAP'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppConstants.space20),

                              ActiveMissionStrip(
                                activeMissions: activeMissions,
                                onManageMissions: () => context.go('/missions'),
                              ),
                            ],
                          );

                          final rightColumn = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              QuickAlertsCard(robots: robots),
                              const SizedBox(height: AppConstants.space20),
                              const OperationalEventsList(),
                            ],
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 7, child: leftColumn),
                                const SizedBox(width: AppConstants.space20),
                                Expanded(flex: 5, child: rightColumn),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                leftColumn,
                                const SizedBox(height: AppConstants.space20),
                                rightColumn,
                              ],
                            );
                          }
                        },
                      ),
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
}
