import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/service_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    required this.onToggleActive,
  });

  final ServiceModel service;
  final VoidCallback onTap;
  final void Function(bool) onToggleActive;

  @override
  Widget build(BuildContext context) {
    return KynzaCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: AppTypography.h3),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${service.category} · ${service.formattedDuration}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                KynzaAmountWidget(
                  amountBif: service.priceBif,
                  style: AppTypography.amountSm,
                ),
              ],
            ),
          ),
          Switch(
            value: service.isActive,
            activeTrackColor: AppColors.primary,
            onChanged: onToggleActive,
          ),
        ],
      ),
    );
  }
}
