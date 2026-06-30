import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/staff_working_hour_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/availability_providers.dart';
import '../widgets/staff_hours_editor.dart';

List<StaffWorkingHourModel> _withDefaults(
  List<StaffWorkingHourModel> custom,
  String staffId,
  String salonId,
) {
  final byDay = {for (final h in custom) h.dayOfWeek: h};
  return List.generate(
    7,
    (day) =>
        byDay[day] ??
        StaffWorkingHourModel(
          staffId: staffId,
          salonId: salonId,
          dayOfWeek: day,
          isClosed: day == 6,
          opensAt: '08:00:00',
          closesAt: '18:00:00',
        ),
  );
}

/// Owner/manager view when editing someone else's hours, and the staff
/// member's own self-service screen (RouteNames.staffAvailability) — both
/// just supply a different staffId/salonId/staffName.
class StaffHoursScreen extends ConsumerStatefulWidget {
  const StaffHoursScreen({
    super.key,
    required this.staffId,
    required this.salonId,
    this.staffName,
  });

  final String staffId;
  final String salonId;
  final String? staffName;

  @override
  ConsumerState<StaffHoursScreen> createState() => _StaffHoursScreenState();
}

class _StaffHoursScreenState extends ConsumerState<StaffHoursScreen> {
  List<StaffWorkingHourModel>? _draft;
  bool? _useSalonHours;

  @override
  Widget build(BuildContext context) {
    final hoursAsync = ref.watch(
      staffWorkingHoursProvider((widget.staffId, widget.salonId)),
    );
    final saving = ref.watch(availabilityNotifierProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.staffName != null
              ? context.l10n.availabilityStaffHoursOf(widget.staffName!)
              : context.l10n.availabilityMyAvailability,
        ),
      ),
      body: hoursAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: KynzaSkeleton(height: 400),
        ),
        error: (_, __) => KynzaErrorState(
          message: context.l10n.availabilityStaffHoursLoadError,
          onRetry: () => ref.invalidate(
            staffWorkingHoursProvider((widget.staffId, widget.salonId)),
          ),
        ),
        data: (custom) {
          _useSalonHours ??= custom.isEmpty;
          _draft ??= _withDefaults(custom, widget.staffId, widget.salonId);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                context.l10n.availabilityStaffHoursScreenHint,
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.availabilityStaffHoursUseSalonTitle),
                value: _useSalonHours!,
                activeTrackColor: AppColors.primary,
                onChanged: (v) => setState(() => _useSalonHours = v),
              ),
              const SizedBox(height: AppSpacing.md),
              if (!_useSalonHours!)
                StaffHoursEditor(
                  hours: _draft!,
                  onChanged: (updated) => setState(() => _draft = updated),
                ),
              const SizedBox(height: AppSpacing.xl),
              KynzaButton(
                label: context.l10n.commonSave,
                isLoading: saving,
                onPressed: () async {
                  final notifier = ref.read(
                    availabilityNotifierProvider.notifier,
                  );
                  try {
                    if (_useSalonHours!) {
                      await notifier.useSalonHours(
                        widget.staffId,
                        widget.salonId,
                      );
                    } else {
                      await notifier.saveStaffHours(
                        widget.staffId,
                        widget.salonId,
                        _draft!,
                      );
                    }
                    if (context.mounted) {
                      showKynzaToast(
                        context,
                        message: context.l10n.availabilityStaffHoursSaveSuccess,
                        level: ToastLevel.success,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showKynzaToast(
                        context,
                        message: e is AppException
                            ? e.message
                            : context.l10n.availabilitySaveFailed,
                        level: ToastLevel.error,
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
