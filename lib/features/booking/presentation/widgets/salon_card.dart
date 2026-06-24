import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/salon_full_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

class SalonCard extends StatelessWidget {
  const SalonCard({super.key, required this.salon, required this.onTap});

  final SalonFullModel salon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KynzaCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.card),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: salon.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: salon.coverUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(color: AppColors.surfaceVariant),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                KynzaAvatar(fullName: salon.name, avatarUrl: salon.logoUrl),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(salon.name, style: AppTypography.h3),
                      if (salon.province != null)
                        Text(
                          '${salon.commune ?? ''} · ${salon.province}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (salon.isVerified)
                  const Icon(
                    Icons.verified,
                    color: AppColors.primary,
                    size: 18,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
