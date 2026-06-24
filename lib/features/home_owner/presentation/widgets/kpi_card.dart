import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.label, this.amountBif, this.value});

  final String label;
  final int? amountBif;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return KynzaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (amountBif != null)
            KynzaAmountWidget(
              amountBif: amountBif!,
              style: AppTypography.amountMd,
            )
          else
            Text(value ?? '—', style: AppTypography.amountMd),
        ],
      ),
    );
  }
}
