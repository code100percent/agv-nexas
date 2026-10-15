import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/config/constants.dart';

/// Stub implementation of WebTwinView for Native Desktop, Mobile, and Headless Tests.
/// Shows high-tech digital twin preview and directs user to WebGL canvas or 2D tactical map.
class WebTwinView extends StatelessWidget {
  final String robotId;
  final String? token;
  final VoidCallback? onSwitchTo2D;

  const WebTwinView({
    super.key,
    required this.robotId,
    this.token,
    this.onSwitchTo2D,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppConstants.space24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: const Icon(
                Icons.view_in_ar_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppConstants.space16),
            Text(
              'THREE.JS WEBGL DIGITAL TWIN RUNTIME',
              style: AppTypography.titleMedium.copyWith(
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Text(
                'WebGL 3D engine operates on Flutter Web via the FastAPI Gateway at /viewer.\n'
                'On Native Desktop/Mobile targets, high-reliability 2D/2.5D metric rendering is available.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppConstants.space20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onSwitchTo2D != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    onPressed: onSwitchTo2D,
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('SWITCH TO 2D MAP'),
                  ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'TARGET: /viewer',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
