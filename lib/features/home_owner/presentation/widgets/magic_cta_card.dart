import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

/// Single contextual call-to-action — never more than one shown at once
/// (R05: max 3 primary actions per screen, this is the highest priority one).
class MagicCtaCard extends StatelessWidget {
  const MagicCtaCard({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.card_,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: AppRadius.card_,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.h3.copyWith(color: AppColors.background),
              ),
            ),
            const Icon(Icons.arrow_forward, color: AppColors.background),
          ],
        ),
      ),
    );
  }
}
