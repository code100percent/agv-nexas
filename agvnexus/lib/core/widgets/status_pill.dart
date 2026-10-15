import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../config/constants.dart';

enum AgvOperatingMode {
  idle,
  navigating,
  charging,
  paused,
  fault,
  estop,
  offline;

  String get displayName {
    switch (this) {
      case AgvOperatingMode.idle:
        return 'IDLE';
      case AgvOperatingMode.navigating:
        return 'NAVIGATING';
      case AgvOperatingMode.charging:
        return 'CHARGING';
      case AgvOperatingMode.paused:
        return 'PAUSED';
      case AgvOperatingMode.fault:
        return 'FAULT';
      case AgvOperatingMode.estop:
        return 'E-STOP';
      case AgvOperatingMode.offline:
        return 'OFFLINE';
    }
  }

  Color get color {
    switch (this) {
      case AgvOperatingMode.idle:
        return AppColors.statusIdle;
      case AgvOperatingMode.navigating:
        return AppColors.statusNavigating;
      case AgvOperatingMode.charging:
        return AppColors.statusCharging;
      case AgvOperatingMode.paused:
        return AppColors.statusPaused;
      case AgvOperatingMode.fault:
        return AppColors.statusFault;
      case AgvOperatingMode.estop:
        return AppColors.statusEstop;
      case AgvOperatingMode.offline:
        return AppColors.textDisabled;
    }
  }
}

class StatusPill extends StatelessWidget {
  final AgvOperatingMode mode;
  final bool showDot;

  const StatusPill({super.key, required this.mode, this.showDot = true});

  @override
  Widget build(BuildContext context) {
    final color = mode.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            mode.displayName,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
