import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/enums/date_range.dart';

/// 3-segment chip row (Aujourd'hui · 7 jours · 30 jours) — custom
/// implementation, no external package (kynza-flutter-architecture.md
/// convention of minimal dependencies).
class KynzaPeriodSelector extends StatelessWidget {
  const KynzaPeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final DateRange selected;
  final ValueChanged<DateRange> onChanged;

  static const _options = [
    DateRange.today,
    DateRange.last7days,
    DateRange.last30days,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in _options)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _Chip(
              label: option.label,
              isSelected: option == selected,
              onTap: () => onChanged(option),
            ),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceVariant : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.xl),
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
