import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/availability_exception_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

const _typeOptions = ['vacation', 'special_closure', 'special_opening'];

/// Bottom-sheet content to create a salon-wide multi-day exception
/// (vacances/fermeture/ouverture spéciale). Public holidays are seeded
/// server-side and read-only here (kynza-booking-engine.md extension);
/// per-staff exceptions are out of scope for this form.
class ExceptionFormWidget extends StatefulWidget {
  const ExceptionFormWidget({
    super.key,
    required this.salonId,
    required this.onSave,
  });

  final String salonId;
  final void Function(AvailabilityExceptionModel) onSave;

  @override
  State<ExceptionFormWidget> createState() => _ExceptionFormWidgetState();
}

class _ExceptionFormWidgetState extends State<ExceptionFormWidget> {
  String _type = 'vacation';
  DateTimeRange? _range;
  TimeOfDay _opensAt = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closesAt = const TimeOfDay(hour: 18, minute: 0);
  late final _labelCtrl = TextEditingController();

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _range,
    );
    if (picked != null && mounted) setState(() => _range = picked);
  }

  Future<void> _pickTime({required bool isOpen}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpen ? _opensAt : _closesAt,
    );
    if (picked == null || !mounted) return;
    setState(() => isOpen ? _opensAt = picked : _closesAt = picked);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    final isOpening = _type == 'special_opening';
    final l10n = context.l10n;
    final typeLabels = {
      'vacation': l10n.availabilityExceptionTypeVacation,
      'special_closure': l10n.availabilityExceptionTypeClosure,
      'special_opening': l10n.availabilityExceptionTypeOpening,
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.availabilityExceptionTitle, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: InputDecoration(
              labelText: l10n.availabilityExceptionTypeLabel,
            ),
            items: [
              for (final type in _typeOptions)
                DropdownMenuItem(value: type, child: Text(typeLabels[type]!)),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'vacation'),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: _pickRange,
            child: Text(
              _range == null
                  ? l10n.availabilityExceptionChooseDates
                  : '${_range!.start.day}/${_range!.start.month} – '
                        '${_range!.end.day}/${_range!.end.month}',
            ),
          ),
          if (isOpening) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isOpen: true),
                    child: Text(
                      l10n.availabilityExceptionOpenTime(
                        _opensAt.format(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isOpen: false),
                    child: Text(
                      l10n.availabilityExceptionCloseTime(
                        _closesAt.format(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          KynzaTextField(
            label: l10n.availabilityExceptionLabelField,
            hint: l10n.availabilityExceptionLabelHint,
            controller: _labelCtrl,
          ),
          const SizedBox(height: AppSpacing.xl),
          KynzaButton(
            label: l10n.commonSave,
            onPressed: _range == null
                ? null
                : () {
                    final label = _labelCtrl.text.trim().isEmpty
                        ? typeLabels[_type]!
                        : _labelCtrl.text.trim();
                    widget.onSave(
                      AvailabilityExceptionModel(
                        salonId: widget.salonId,
                        exceptionType: _type,
                        startDate: _range!.start,
                        endDate: _range!.end,
                        label: label,
                        isClosed: !isOpening,
                        opensAt: isOpening ? _fmt(_opensAt) : null,
                        closesAt: isOpening ? _fmt(_closesAt) : null,
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
