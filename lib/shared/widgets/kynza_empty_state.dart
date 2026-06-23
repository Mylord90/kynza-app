import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import 'kynza_button.dart';

/// CTA is mandatory — no screen ends here without an action (R04/R05).
class KynzaEmptyState extends StatelessWidget {
  const KynzaEmptyState({
    super.key,
    this.icon,
    this.svgAsset,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onCta,
  });

  final IconData? icon;
  final String? svgAsset;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(svgAsset!, width: 80, height: 80)
            else
              Icon(
                icon ?? Icons.inbox_outlined,
                size: 80,
                color: AppColors.primary,
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTypography.h2, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppTypography.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            KynzaButton(label: ctaLabel, onPressed: onCta),
          ],
        ),
      ),
    );
  }
}
