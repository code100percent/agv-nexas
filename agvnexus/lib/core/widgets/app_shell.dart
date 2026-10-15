import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../config/constants.dart';
import '../network/connection_state.dart';
import 'connection_badge.dart';
import '../../features/auth/presentation/auth_controller.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentTime = DateTime.now();
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/overview')) return 0;
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/digital-twin')) return 2;
    if (location.startsWith('/robots')) return 3;
    if (location.startsWith('/missions')) return 4;
    if (location.startsWith('/telemetry')) return 5;
    if (location.startsWith('/settings')) return 6;
    return 0;
  }

  void _onDestinationSelected(int index) {
    switch (index) {
      case 0:
        context.go('/overview');
        break;
      case 1:
        context.go('/map');
        break;
      case 2:
        context.go('/digital-twin');
        break;
      case 3:
        context.go('/robots');
        break;
      case 4:
        context.go('/missions');
        break;
      case 5:
        context.go('/telemetry');
        break;
      case 6:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).value;
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('yyyy-MM-dd');
    final selectedIndex = _calculateSelectedIndex(context);

    final isMobile =
        MediaQuery.sizeOf(context).width < AppConstants.mobileBreakpoint;

    if (isMobile) {
      return _buildMobileScaffold(
        context,
        selectedIndex,
        authUser,
        timeFormat.format(_currentTime),
      );
    }

    return _buildDesktopScaffold(
      context,
      selectedIndex,
      authUser,
      timeFormat.format(_currentTime),
      dateFormat.format(_currentTime),
    );
  }

  Widget _buildDesktopScaffold(
    BuildContext context,
    int selectedIndex,
    dynamic authUser,
    String timeStr,
    String dateStr,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Navigation Rail Sidebar
          Container(
            width: AppConstants.desktopNavRailWidth,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(color: AppColors.borderSubtle, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusSm,
                          ),
                          border: Border.all(color: AppColors.primaryGlow),
                        ),
                        child: const Icon(
                          Icons.precision_manufacturing_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AGV NEXUS',
                              style: AppTypography.titleMedium.copyWith(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'COMMAND CENTER',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Nav Items List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    children: [
                      _navItem(
                        0,
                        Icons.dashboard_outlined,
                        Icons.dashboard_rounded,
                        'Operations Overview',
                        selectedIndex,
                      ),
                      _navItem(
                        1,
                        Icons.map_outlined,
                        Icons.map_rounded,
                        'Live 2D Map',
                        selectedIndex,
                      ),
                      _navItem(
                        2,
                        Icons.view_in_ar_outlined,
                        Icons.view_in_ar_rounded,
                        '3D Digital Twin',
                        selectedIndex,
                      ),
                      _navItem(
                        3,
                        Icons.smart_toy_outlined,
                        Icons.smart_toy_rounded,
                        'Robot Fleet',
                        selectedIndex,
                      ),
                      _navItem(
                        4,
                        Icons.alt_route_outlined,
                        Icons.alt_route_rounded,
                        'Missions',
                        selectedIndex,
                      ),
                      _navItem(
                        5,
                        Icons.query_stats_outlined,
                        Icons.query_stats_rounded,
                        'Telemetry Bus',
                        selectedIndex,
                      ),
                      const Divider(color: AppColors.borderSubtle, height: 24),
                      _navItem(
                        6,
                        Icons.settings_outlined,
                        Icons.settings_rounded,
                        'System Settings',
                        selectedIndex,
                      ),
                    ],
                  ),
                ),

                // Bottom User Profile Info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceRaised,
                    border: Border(
                      top: BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withAlpha(40),
                        child: Text(
                          (authUser?.fullName ?? 'OP')[0].toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              authUser?.fullName ?? 'Operator',
                              style: AppTypography.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              authUser?.role.displayName ?? 'Operator',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        tooltip: 'Sign Out',
                        onPressed: () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .signOut();
                          if (context.mounted) {
                            context.go('/sign-in');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Screen Content Area
          Expanded(
            child: Column(
              children: [
                // Desktop Context-Aware Top Bar
                Container(
                  height: AppConstants.desktopTopBarHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.factory_outlined,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                authUser?.organizationName ?? 'Nexus Gigafactory 1',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceRaised,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusXs,
                                ),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Text(
                                'ZONE: ALPHA-1',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Real-time Clock
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$dateStr • $timeStr UTC',
                            style: AppTypography.telemetryCompact.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      const ConnectionBadge(status: ConnectionStatus.simulated),
                    ],
                  ),
                ),

                // Child Page Content
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileScaffold(
    BuildContext context,
    int selectedIndex,
    dynamic authUser,
    String timeStr,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 12,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.precision_manufacturing_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text('AGV NEXUS', style: AppTypography.titleMedium),
            ],
          ),
        ),
        actions: [
          const ConnectionBadge(
            status: ConnectionStatus.simulated,
            compact: true,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 18),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/sign-in');
            },
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, 4),
        onDestinationSelected: (idx) {
          switch (idx) {
            case 0:
              context.go('/overview');
              break;
            case 1:
              context.go('/map');
              break;
            case 2:
              context.go('/robots');
              break;
            case 3:
              context.go('/missions');
              break;
            case 4:
              context.go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy_rounded),
            label: 'Fleet',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined),
            selectedIcon: Icon(Icons.alt_route_rounded),
            label: 'Missions',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
    int selectedIndex,
  ) {
    final isSelected = index == selectedIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => _onDestinationSelected(index),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withAlpha(25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withAlpha(80)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : unselectedIcon,
                size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: isSelected
                      ? AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                        )
                      : AppTypography.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
