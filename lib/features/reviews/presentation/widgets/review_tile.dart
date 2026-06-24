import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/review/review_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

class ReviewTile extends StatelessWidget {
  const ReviewTile({
    super.key,
    required this.review,
    this.clientName,
    this.trailing,
  });

  final ReviewModel review;
  final String? clientName;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final displayName = review.isAnonymous
        ? 'Anonyme'
        : (clientName ?? 'Client');

    return KynzaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              KynzaAvatar(
                fullName: review.isAnonymous ? 'A' : displayName,
                size: AvatarSize.sm,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Row(
                  children: [
                    Text(displayName, style: AppTypography.h3),
                    if (review.isVerified) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: AppColors.success,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                review.starDisplay,
                style: const TextStyle(color: AppColors.primary),
              ),
              if (review.createdAt != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${review.createdAt!.day}/${review.createdAt!.month}/${review.createdAt!.year}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(review.comment!, style: AppTypography.body),
          ],
          if (review.hasOwnerReply) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Réponse du salon', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.xs),
                  Text(review.ownerReply!, style: AppTypography.bodySmall),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
