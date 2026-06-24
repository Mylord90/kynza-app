import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

/// Dashboard KPI tile — left gold accent bar, optional trend chip.
/// Monetary KPIs pass [amountBif] (rendered via [KynzaAmountWidget], which
/// already respects the global confidential-mode toggle); non-monetary
/// KPIs (counts, percentages) pass [value] instead.
class KynzaKpiCard extends StatelessWidget {
  const KynzaKpiCard({
    super.key,
    required this.label,
    this.amountBif,
    this.value,
    this.trendPct,
    this.icon,
  });

  final String label;
  final int? amountBif;
  final String? value;

  /// Positive = up (green), negative = down (red), null = no trend shown.
  final int? trendPct;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: AppTypography.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (icon != null)
                        Icon(icon, size: 14, color: AppColors.textSecondary),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (amountBif != null)
                    KynzaAmountWidget(
                      amountBif: amountBif!,
                      style: AppTypography.amountMd,
                    )
                  else
                    Text(value ?? '—', style: AppTypography.amountMd),
                  if (trendPct != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _TrendChip(trendPct: trendPct!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.trendPct});

  final int trendPct;

  @override
  Widget build(BuildContext context) {
    final isUp = trendPct >= 0;
    final color = isUp ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isUp ? AppColors.successBg : AppColors.errorBg,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        '${isUp ? '▲' : '▼'} ${trendPct.abs()}%',
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
