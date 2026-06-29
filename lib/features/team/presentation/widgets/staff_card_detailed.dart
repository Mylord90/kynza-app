import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/staff_profile_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../booking/application/providers/booking_providers.dart';
import '../../../staff/presentation/widgets/staff_role_badge.dart';

final _staffWeekStatsProvider = FutureProvider.family<(int, int), String>((
  ref,
  staffId,
) async {
  final now = DateTime.now();
  final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  final bookings = await ref
      .read(bookingRepositoryProvider)
      .getPractitionerBookingsInRange(
        staffId,
        weekStart,
        weekStart.add(const Duration(days: 7)),
      );
  final completed = bookings
      .where((b) => b.status.name == 'completed')
      .toList();
  final revenue = completed.fold(0, (sum, b) => sum + b.amountBif);
  return (completed.length, revenue);
});

/// Owner-only team list row — adds this-week RDV/revenue (R11: revenue
/// gated by [isOwner]) and an availability dot on top of the basic
/// [StaffCard] used elsewhere.
class StaffCardDetailed extends ConsumerWidget {
  const StaffCardDetailed({
    super.key,
    required this.staff,
    required this.isOwner,
    required this.onTap,
  });

  final StaffProfileModel staff;
  final bool isOwner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = staff.id == null
        ? null
        : ref.watch(_staffWeekStatsProvider(staff.id!));

    return KynzaCard(
      onTap: onTap,
      child: Row(
        children: [
          Stack(
            children: [
              KynzaAvatar(
                fullName: staff.displayName,
                avatarUrl: staff.avatarUrl,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: staff.isActive
                        ? AppColors.success
                        : AppColors.textMuted,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.displayName, style: AppTypography.h3),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    StaffRoleBadge(
                      role: staff.role,
                      isPending: staff.isPending,
                    ),
                    if (staff.specialties.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          children: [
                            for (final s in staff.specialties.take(2))
                              Text(
                                s,
                                style: AppTypography.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isOwner && statsAsync != null)
            statsAsync.maybeWhen(
              data: (stats) {
                final (count, revenue) = stats;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$count RDV', style: AppTypography.bodySmall),
                    KynzaAmountWidget(
                      amountBif: revenue,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
