import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/availability_override_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

/// Bottom-sheet content to block/unblock a single date, optionally with
/// custom hours. Used by both the management screen and blocked-slots list.
class DayOverridePicker extends StatefulWidget {
  const DayOverridePicker({
    super.key,
    required this.date,
    required this.salonId,
    this.staffId,
    this.existing,
    required this.onSave,
  });

  final DateTime date;
  final String salonId;
  final String? staffId;
  final AvailabilityOverrideModel? existing;
  final void Function(AvailabilityOverrideModel) onSave;

  @override
  State<DayOverridePicker> createState() => _DayOverridePickerState();
}

class _DayOverridePickerState extends State<DayOverridePicker> {
  late bool _isAvailable = widget.existing?.isAvailable ?? false;
  late final _reasonCtrl = TextEditingController(text: widget.existing?.reason);

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.date.day}/${widget.date.month}/${widget.date.year}',
            style: AppTypography.h2,
          ),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ouvert ce jour-là'),
            value: _isAvailable,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => setState(() => _isAvailable = v),
          ),
          if (!_isAvailable) ...[
            const SizedBox(height: AppSpacing.md),
            KynzaTextField(
              label: 'Raison (optionnel)',
              hint: 'Congé, jour férié, formation…',
              controller: _reasonCtrl,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          KynzaButton(
            label: 'Enregistrer',
            onPressed: () {
              widget.onSave(
                AvailabilityOverrideModel(
                  id: widget.existing?.id,
                  salonId: widget.salonId,
                  staffId: widget.staffId,
                  date: widget.date,
                  isAvailable: _isAvailable,
                  reason: _reasonCtrl.text.trim().isEmpty
                      ? null
                      : _reasonCtrl.text.trim(),
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
