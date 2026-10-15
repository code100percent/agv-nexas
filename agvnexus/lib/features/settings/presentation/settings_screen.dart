import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/config/constants.dart';
import '../../../core/config/app_config.dart';
import '../../../core/widgets/industrial_card.dart';
import '../../auth/presentation/auth_controller.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return const AppConfig();
});

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).value;
    final config = ref.watch(appConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SYSTEM & ORGANIZATION CONFIGURATION',
              style: AppTypography.displayMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Manage tenant profile, role permissions, and connection parameters.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppConstants.space20),

            // Operator Profile Panel
            IndustrialCard(
              title: 'AUTHENTICATED OPERATOR PROFILE',
              subtitle: 'Active session credentials',
              icon: Icons.badge_outlined,
              child: Column(
                children: [
                  _infoRow(
                    'Operator Name',
                    authUser?.fullName ?? 'Demo Operator',
                  ),
                  _infoRow(
                    'Email Identifier',
                    authUser?.email ?? 'operator@agvnexus.local',
                  ),
                  _infoRow(
                    'Assigned Role',
                    authUser?.role.displayName ?? 'Factory Operator',
                  ),
                  _infoRow(
                    'Organization Tenant',
                    authUser?.organizationName ?? 'Nexus Gigafactory 1',
                  ),
                  _infoRow(
                    'Session Security Tier',
                    config.hasSupabaseConfig
                        ? 'Supabase Auth & PostgreSQL RLS (Phase 2)'
                        : 'Deterministic Mock Directory (Simulation Mode)',
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(authControllerProvider.notifier)
                            .signOut();
                        if (context.mounted) {
                          context.go('/sign-in');
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text('TERMINATE OPERATOR SESSION'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.space20),

            // Architecture & Environment Settings
            IndustrialCard(
              title: 'INTEGRATION TIER & ENVIRONMENT',
              subtitle: 'Current operational deployment mode',
              icon: Icons.tune_rounded,
              child: Column(
                children: [
                  _infoRow('Application Version', config.appVersion),
                  _infoRow(
                    'Active Environment',
                    config.environment.toUpperCase(),
                  ),
                  _infoRow(
                    'Simulation Mode Flag',
                    config.isSimulatedMode
                        ? 'ENABLED (Phase 1 & 2 Hybrid)'
                        : 'DISABLED',
                  ),
                  _infoRow('Backend Gateway REST API', config.apiBaseUrl),
                  _infoRow('Backend Gateway WebSocket', config.wsBaseUrl),
                  _infoRow(
                    'Supabase Cloud Sync',
                    config.hasSupabaseConfig
                        ? 'CONFIGURED (RLS Active)'
                        : 'AWAITING PROJECT CREDENTIALS (PASS VIA .ENV)',
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.space20),

            // Hardware Safety Disclaimer
            IndustrialCard(
              title: 'SAFETY & COMPLIANCE REQUIREMENTS',
              subtitle:
                  'ISO 3691-4 / ANSI RIA R15.08 industrial mobile robot standards',
              icon: Icons.verified_user_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safety Architecture Notice:',
                    style: AppTypography.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '1. Cloud and local web interfaces NEVER replace dedicated physical hardware emergency stop circuits.\n'
                    '2. AMR motor controllers and Nav2 autonomy run locally on the robot computer; loss of cloud or Wi-Fi connectivity must never impair safe in-place stopping.\n'
                    '3. All missions dispatched through AGV Nexus undergo kinematic and payload capacity validation before command issuance.',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTypography.bodySmall)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: AppTypography.telemetryCompact,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
