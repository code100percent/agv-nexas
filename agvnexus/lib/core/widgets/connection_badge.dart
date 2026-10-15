import 'package:flutter/material.dart';
import '../network/connection_state.dart';
import '../theme/app_typography.dart';
import '../config/constants.dart';

/// Distinctive industrial status indicator for system connectivity.
/// Prominently displays SIMULATED / DEMO vs LIVE TELEMETRY to satisfy operating rules.
class ConnectionBadge extends StatelessWidget {
  final ConnectionStatus status;
  final VoidCallback? onTap;
  final bool compact;

  const ConnectionBadge({
    super.key,
    required this.status,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = status.color;
    final displayLabel = compact && status == ConnectionStatus.simulated
        ? 'SIMULATED'
        : status.label;

    return Tooltip(
      message: status == ConnectionStatus.simulated
          ? 'Phase 1 Deterministic Mock Data (No fake live hardware connection)'
          : 'Status: ${status.label}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 10,
            vertical: compact ? 3.5 : 5,
          ),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            border: Border.all(color: statusColor.withAlpha(80), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withAlpha(120),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                displayLabel,
                style: AppTypography.labelSmall.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: compact ? 0.4 : 0.8,
                  fontSize: compact ? 9.0 : 10.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
