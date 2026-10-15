import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../config/constants.dart';

/// Reusable layered panel component with precise borders and optional header.
class IndustrialCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  const IndustrialCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: borderColor ?? AppColors.borderSubtle,
      width: 1,
    );

    Widget content = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || icon != null || trailing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                  ],
                  if (title != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title!,
                            style: AppTypography.titleMedium.copyWith(
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(subtitle!, style: AppTypography.bodySmall),
                          ],
                        ],
                      ),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          if (title != null || icon != null || trailing != null)
            const Divider(height: 1, color: AppColors.borderSubtle),
          Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: content,
      );
    }

    return content;
  }
}
