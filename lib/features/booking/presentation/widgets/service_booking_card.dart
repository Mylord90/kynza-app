import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/service_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

class ServiceBookingCard extends StatelessWidget {
  const ServiceBookingCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  final ServiceModel service;
  final VoidCallback onTap;

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
                  service.formattedDuration,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          KynzaAmountWidget(
            amountBif: service.priceBif,
            style: AppTypography.amountSm,
          ),
        ],
      ),
    );
  }
}
