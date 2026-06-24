import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/availability_override_model.dart';

const _dayShortLabels = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

/// Horizontal strip of the next 14 days — gold border = today,
/// red fill = blocked override, tap any day to edit it.
class WeekScheduleEditor extends StatelessWidget {
  const WeekScheduleEditor({
    super.key,
    required this.overrides,
    required this.onDayTap,
    this.daysAhead = 14,
  });

  final List<AvailabilityOverrideModel> overrides;
  final void Function(DateTime date, AvailabilityOverrideModel? existing)
  onDayTap;
  final int daysAhead;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return SizedBox(
      height: 84,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: daysAhead,
        itemBuilder: (context, index) {
          final date = todayOnly.add(Duration(days: index));
          final existing = overrides
              .where((o) => _isSameDay(o.date, date))
              .firstOrNull;
          final isBlocked = existing != null && !existing.isAvailable;
          final isToday = index == 0;

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: InkWell(
              onTap: () => onDayTap(date, existing),
              borderRadius: AppRadius.md_,
              child: Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isBlocked
                      ? AppColors.errorBg
                      : AppColors.surfaceVariant,
                  borderRadius: AppRadius.md_,
                  border: Border.all(
                    color: isToday ? AppColors.primary : AppColors.border,
                    width: isToday ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _dayShortLabels[date.weekday - 1],
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${date.day}', style: AppTypography.h3),
                    if (isBlocked)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.block,
                          size: 12,
                          color: AppColors.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
