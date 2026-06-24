import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/staff_profile_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

class PractitionerCard extends StatelessWidget {
  const PractitionerCard({
    super.key,
    required this.practitioner,
    required this.isSelected,
    required this.onTap,
  });

  /// null = "N'importe quel praticien"
  final StaffProfileModel? practitioner;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KynzaCard(
      onTap: onTap,
      isSelected: isSelected,
      child: Row(
        children: [
          practitioner == null
              ? const CircleAvatar(
                  backgroundColor: AppColors.surfaceVariant,
                  child: Icon(Icons.shuffle, color: AppColors.primary),
                )
              : KynzaAvatar(
                  fullName: practitioner!.displayName,
                  avatarUrl: practitioner!.avatarUrl,
                ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  practitioner?.displayName ?? "N'importe quel praticien",
                  style: AppTypography.h3,
                ),
                if (practitioner != null &&
                    practitioner!.specialties.isNotEmpty)
                  Text(
                    practitioner!.specialties.join(' · '),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, color: AppColors.primary),
        ],
      ),
    );
  }
}
