import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/staff_working_hour_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

/// Same 7-row shape as WorkingHoursEditor (salon hours), kept as its own
/// small widget rather than a shared generic component since the two
/// models (StaffWorkingHourModel vs WorkingHourModel) are independent
/// tables with no common interface — duplicating ~60 lines here is
/// cheaper than forcing an artificial abstraction across them.
class StaffHoursEditor extends StatelessWidget {
  const StaffHoursEditor({
    super.key,
    required this.hours,
    required this.onChanged,
  });

  final List<StaffWorkingHourModel> hours;
  final void Function(List<StaffWorkingHourModel>) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < hours.length; i++) ...[
          _DayRow(
            hour: hours[i],
            onChanged: (updated) {
              final next = [...hours];
              next[i] = updated;
              onChanged(next);
            },
          ),
          if (i != hours.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.hour, required this.onChanged});

  final StaffWorkingHourModel hour;
  final void Function(StaffWorkingHourModel) onChanged;

  Future<void> _pickTime(BuildContext context, {required bool isOpen}) async {
    final initial =
        _parse(isOpen ? hour.opensAt : hour.closesAt) ??
        TimeOfDay(hour: isOpen ? 8 : 18, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
    onChanged(
      isOpen
          ? hour.copyWith(opensAt: formatted)
          : hour.copyWith(closesAt: formatted),
    );
  }

  TimeOfDay? _parse(String? value) {
    if (value == null || value.length < 5) return null;
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  Widget build(BuildContext context) {
    return KynzaCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(hour.dayLabel, style: AppTypography.h3),
          ),
          Switch(
            value: !hour.isClosed,
            activeTrackColor: AppColors.primary,
            onChanged: (open) => onChanged(hour.copyWith(isClosed: !open)),
          ),
          if (hour.isClosed)
            Expanded(
              child: Text(
                'Fermé',
                textAlign: TextAlign.end,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _TimeChip(
                    label: hour.opensAt?.substring(0, 5) ?? '--:--',
                    onTap: () => _pickTime(context, isOpen: true),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: Text('–'),
                  ),
                  _TimeChip(
                    label: hour.closesAt?.substring(0, 5) ?? '--:--',
                    onTap: () => _pickTime(context, isOpen: false),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.sm_,
      child: Container(
        height: AppSpacing.xxl,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.sm_,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(label, style: AppTypography.mono),
      ),
    );
  }
}
