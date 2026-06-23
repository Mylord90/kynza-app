import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

enum KynzaBadgeVariant { gold, success, error, warning, neutral, info }

class KynzaBadge extends StatelessWidget {
  const KynzaBadge({
    super.key,
    required this.label,
    this.variant = KynzaBadgeVariant.neutral,
  });

  final String label;
  final KynzaBadgeVariant variant;

  Color get _color => switch (variant) {
    KynzaBadgeVariant.gold => AppColors.primary,
    KynzaBadgeVariant.success => AppColors.success,
    KynzaBadgeVariant.error => AppColors.error,
    KynzaBadgeVariant.warning => AppColors.warning,
    KynzaBadgeVariant.neutral => AppColors.textSecondary,
    KynzaBadgeVariant.info => AppColors.info,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill_,
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}
