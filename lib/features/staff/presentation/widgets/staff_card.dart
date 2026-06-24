import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/staff_profile_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import 'staff_role_badge.dart';

class StaffCard extends StatelessWidget {
  const StaffCard({
    super.key,
    required this.staff,
    required this.onTap,
    required this.onToggleActive,
  });

  final StaffProfileModel staff;
  final VoidCallback onTap;
  final void Function(bool) onToggleActive;

  @override
  Widget build(BuildContext context) {
    return KynzaCard(
      onTap: onTap,
      child: Row(
        children: [
          KynzaAvatar(fullName: staff.displayName, avatarUrl: staff.avatarUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.displayName, style: AppTypography.h3),
                const SizedBox(height: AppSpacing.xs),
                StaffRoleBadge(role: staff.role, isPending: staff.isPending),
              ],
            ),
          ),
          Switch(
            value: staff.isActive,
            activeTrackColor: AppColors.primary,
            onChanged: onToggleActive,
          ),
        ],
      ),
    );
  }
}
