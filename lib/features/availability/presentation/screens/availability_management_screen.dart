import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../application/providers/availability_providers.dart';
import '../widgets/day_override_picker.dart';
import '../widgets/week_schedule_editor.dart';
import 'blocked_slots_screen.dart';
import 'breaks_management_screen.dart';
import 'exceptions_calendar_screen.dart';
import 'salon_hours_screen.dart';
import 'staff_hours_screen.dart';
import 'staff_picker_screen.dart';

/// Navigation hub for every availability concern (Phase 2.2 / Module 3).
/// The Phase 2 single-day override editor (week strip + blocked-slots
/// list) stays exactly where it was — reachable via "Jours bloqués
/// (ponctuel)" — nothing from that flow was removed or changed.
class AvailabilityManagementScreen extends ConsumerWidget {
  const AvailabilityManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.availabilityManagementTitle)),
      body: salon == null
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: KynzaSkeleton(height: 84),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _HubRow(
                  icon: Icons.store_outlined,
                  label: context.l10n.availabilitySalonHoursTitle,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SalonHoursScreen()),
                  ),
                ),
                _HubRow(
                  icon: Icons.badge_outlined,
                  label: context.l10n.availabilityHubStaffHoursLabel,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StaffPickerScreen(
                        salonId: salon.id,
                        title: context.l10n.availabilityHubStaffHoursLabel,
                        onSelect: (member) => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StaffHoursScreen(
                              staffId: member.id!,
                              salonId: salon.id,
                              staffName: member.displayName,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _HubRow(
                  icon: Icons.free_breakfast_outlined,
                  label: context.l10n.availabilityHubBreaksLabel,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StaffPickerScreen(
                        salonId: salon.id,
                        title: context.l10n.availabilityHubBreaksLabel,
                        onSelect: (member) => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BreaksManagementScreen(
                              staffId: member.id!,
                              salonId: salon.id,
                              staffName: member.displayName,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _HubRow(
                  icon: Icons.event_note_outlined,
                  label: context.l10n.availabilityExceptionsLabel,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ExceptionsCalendarScreen(salonId: salon.id),
                    ),
                  ),
                ),
                _HubRow(
                  icon: Icons.event_busy_outlined,
                  label: context.l10n.availabilityBlockedLabel,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlockedSlotsScreen(salonId: salon.id),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.l10n.availabilityHubTouchHint,
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.lg),
                _OverridesStrip(salonId: salon.id),
              ],
            ),
    );
  }
}

class _HubRow extends StatelessWidget {
  const _HubRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: KynzaCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTypography.h3)),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _OverridesStrip extends ConsumerWidget {
  const _OverridesStrip({required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overridesAsync = ref.watch(salonOverridesProvider(salonId));

    return overridesAsync.when(
      loading: () => const KynzaSkeleton(height: 84),
      error: (_, __) => KynzaErrorState(
        message: context.l10n.availabilityLoadError,
        onRetry: () => ref.invalidate(salonOverridesProvider(salonId)),
      ),
      data: (overrides) => WeekScheduleEditor(
        overrides: overrides,
        onDayTap: (date, existing) => showKynzaBottomSheet(
          context,
          builder: (_) => DayOverridePicker(
            date: date,
            salonId: salonId,
            existing: existing,
            onSave: (override) async {
              try {
                await ref
                    .read(availabilityNotifierProvider.notifier)
                    .save(override);
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
        ),
      ),
    );
  }
}
