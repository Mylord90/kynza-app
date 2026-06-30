import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/analytics/top_staff_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

/// R11 — a colleague's revenue must never reach a non-owner viewer, even
/// in a dashboard summary. [isOwner] gates the [KynzaAmountWidget]; every
/// other role only ever sees the booking count.
class KynzaTopStaffRow extends StatelessWidget {
  const KynzaTopStaffRow({
    super.key,
    required this.staff,
    required this.isOwner,
  });

  final List<TopStaffModel> staff;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.dashboardTopStaffTitle, style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: staff.length,
            itemBuilder: (context, index) {
              final member = staff[index];
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: SizedBox(
                  width: 84,
                  child: Column(
                    children: [
                      KynzaAvatar(
                        fullName: member.displayName,
                        avatarUrl: member.avatarUrl,
                        size: AvatarSize.lg,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        member.displayName,
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        context.l10n.dashboardStaffRdvCount(member.bookingCount),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (isOwner)
                        KynzaAmountWidget(
                          amountBif: member.revenueBif,
                          style: AppTypography.amountSm,
                        ),
                    ],
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
