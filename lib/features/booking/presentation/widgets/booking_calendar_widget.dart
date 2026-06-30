import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';

const _weekdayLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

/// Lightweight custom month calendar — no third-party calendar package
/// (R13: keep the dependency/perf footprint minimal on entry-level devices).
class BookingCalendarWidget extends StatefulWidget {
  const BookingCalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.closedDates = const {},
  });

  final DateTime? selectedDate;
  final void Function(DateTime) onDateSelected;
  final Set<DateTime> closedDates;

  @override
  State<BookingCalendarWidget> createState() => _BookingCalendarWidgetState();
}

class _BookingCalendarWidgetState extends State<BookingCalendarWidget> {
  late DateTime _visibleMonth = DateTime(
    widget.selectedDate?.year ?? DateTime.now().year,
    widget.selectedDate?.month ?? DateTime.now().month,
  );

  bool _isClosed(DateTime day) => widget.closedDates.any(
    (d) => d.year == day.year && d.month == day.month && d.day == day.day,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final monthLabels = [
      l10n.commonMonthJanuary,
      l10n.commonMonthFebruary,
      l10n.commonMonthMarch,
      l10n.commonMonthApril,
      l10n.commonMonthMay,
      l10n.commonMonthJune,
      l10n.commonMonthJuly,
      l10n.commonMonthAugust,
      l10n.commonMonthSeptember,
      l10n.commonMonthOctober,
      l10n.commonMonthNovember,
      l10n.commonMonthDecember,
    ];
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final leadingBlanks = firstOfMonth.weekday - 1;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(
                () => _visibleMonth = DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month - 1,
                ),
              ),
            ),
            Text(
              '${monthLabels[_visibleMonth.month - 1]} ${_visibleMonth.year}',
              style: AppTypography.h3,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(
                () => _visibleMonth = DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month + 1,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            for (final l in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    l,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemCount: leadingBlanks + daysInMonth,
          itemBuilder: (context, index) {
            if (index < leadingBlanks) return const SizedBox.shrink();
            final day = DateTime(
              _visibleMonth.year,
              _visibleMonth.month,
              index - leadingBlanks + 1,
            );
            final isPast = day.isBefore(todayOnly);
            final isToday = day == todayOnly;
            final isSelected =
                widget.selectedDate != null &&
                day.year == widget.selectedDate!.year &&
                day.month == widget.selectedDate!.month &&
                day.day == widget.selectedDate!.day;
            final isClosed = _isClosed(day);
            final disabled = isPast || isClosed;

            return Padding(
              padding: const EdgeInsets.all(2),
              child: InkWell(
                onTap: disabled ? null : () => widget.onDateSelected(day),
                borderRadius: AppRadius.sm_,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: AppRadius.sm_,
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary)
                        : null,
                  ),
                  child: disabled
                      ? Text(
                          '${day.day}',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textMuted,
                            decoration: isClosed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        )
                      : Text(
                          '${day.day}',
                          style: AppTypography.body.copyWith(
                            color: isSelected
                                ? AppColors.background
                                : AppColors.textPrimary,
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
