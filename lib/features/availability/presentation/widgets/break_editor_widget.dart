import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/staff_break_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

/// Bottom-sheet content to add a recurring weekly break for one staff
/// member — which staff is chosen one level up (StaffPickerScreen), so
/// this widget only needs the day/time/label inputs.
class BreakEditorWidget extends StatefulWidget {
  const BreakEditorWidget({
    super.key,
    required this.staffId,
    required this.salonId,
    required this.onSave,
  });

  final String staffId;
  final String salonId;
  final void Function(StaffBreakModel) onSave;

  @override
  State<BreakEditorWidget> createState() => _BreakEditorWidgetState();
}

class _BreakEditorWidgetState extends State<BreakEditorWidget> {
  int _dayOfWeek = 0;
  TimeOfDay _start = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 13, minute: 0);
  TextEditingController? _labelCtrl;

  @override
  void dispose() {
    _labelCtrl?.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    setState(() => isStart ? _start = picked : _end = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    _labelCtrl ??= TextEditingController(text: l10n.availabilityBreakDefaultLabel);
    final dayLabels = [
      l10n.weekdayMonday,
      l10n.weekdayTuesday,
      l10n.weekdayWednesday,
      l10n.weekdayThursday,
      l10n.weekdayFriday,
      l10n.weekdaySaturday,
      l10n.weekdaySunday,
    ];
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.availabilityNewBreakTitle, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<int>(
            initialValue: _dayOfWeek,
            decoration: InputDecoration(labelText: l10n.availabilityBreakDayLabel),
            items: [
              for (var i = 0; i < 7; i++)
                DropdownMenuItem(value: i, child: Text(dayLabels[i])),
            ],
            onChanged: (v) => setState(() => _dayOfWeek = v ?? 0),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(isStart: true),
                  child: Text(l10n.availabilityBreakStartTime(_start.format(context))),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(isStart: false),
                  child: Text(l10n.availabilityBreakEndTime(_end.format(context))),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          KynzaTextField(label: l10n.availabilityBreakLabelField, controller: _labelCtrl!),
          const SizedBox(height: AppSpacing.xl),
          KynzaButton(
            label: l10n.commonAdd,
            onPressed: () {
              widget.onSave(
                StaffBreakModel(
                  staffId: widget.staffId,
                  salonId: widget.salonId,
                  dayOfWeek: _dayOfWeek,
                  startTime: _fmt(_start),
                  endTime: _fmt(_end),
                  label: _labelCtrl!.text.trim().isEmpty
                      ? l10n.availabilityBreakFallbackLabel
                      : _labelCtrl!.text.trim(),
                ),
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
