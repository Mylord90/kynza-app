import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/analytics/top_service_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

class KynzaTopServicesList extends StatelessWidget {
  const KynzaTopServicesList({
    super.key,
    required this.services,
    this.onSeeAll,
    this.maxVisible = 5,
  });

  final List<TopServiceModel> services;
  final VoidCallback? onSeeAll;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final visible = services.take(maxVisible).toList();
    final hasMore = services.length > maxVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.dashboardTopServicesTitle,
              style: AppTypography.h3,
            ),
            if (hasMore && onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: Text(
                  context.l10n.dashboardServiceSeeAll,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 92,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final service = visible[index];
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: SizedBox(
                  width: 168,
                  child: KynzaCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.serviceName,
                          style: AppTypography.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          context.l10n.dashboardServiceRdvCount(
                            service.bookingCount,
                          ),
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        KynzaAmountWidget(
                          amountBif: service.totalRevenueBif,
                          style: AppTypography.amountSm,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
