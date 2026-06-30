import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/review/salon_rating_model.dart';

class RatingSummaryWidget extends StatelessWidget {
  const RatingSummaryWidget({
    super.key,
    required this.rating,
    this.compact = false,
  });

  final SalonRatingModel rating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final distribution = rating.distribution;
    final stars = [5, 4, 3, 2, 1];

    return Padding(
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                rating.averageRating.toStringAsFixed(1),
                style: AppTypography.mono.copyWith(
                  fontSize: compact ? 28 : 48,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '★' * rating.averageRating.round().clamp(0, 5) +
                    '☆' * (5 - rating.averageRating.round().clamp(0, 5)),
                style: const TextStyle(color: AppColors.primary, fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.reviewsVerifiedCount(rating.totalReviews),
                style: AppTypography.bodySmall,
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < stars.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text('${stars[i]}★', style: AppTypography.bodySmall),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9999),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: distribution[i] / 100,
                              ),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, value, _) => Container(
                                height: 6,
                                color: AppColors.surfaceVariant,
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: value.clamp(0.0, 1.0),
                                  child: Container(color: AppColors.primary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
