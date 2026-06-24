import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../application/providers/availability_providers.dart';
import '../widgets/day_override_picker.dart';
import '../widgets/week_schedule_editor.dart';
import 'blocked_slots_screen.dart';

class AvailabilityManagementScreen extends ConsumerWidget {
  const AvailabilityManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Disponibilités'),
        actions: [
          if (salon != null)
            IconButton(
              icon: const Icon(Icons.event_busy_outlined),
              tooltip: 'Jours bloqués',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlockedSlotsScreen(salonId: salon.id),
                ),
              ),
            ),
        ],
      ),
      body: salon == null
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: KynzaSkeleton(height: 84),
            )
          : _Body(salonId: salon.id),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overridesAsync = ref.watch(salonOverridesProvider(salonId));

    return overridesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: KynzaSkeleton(height: 84),
      ),
      error: (_, __) => KynzaErrorState(
        message: 'Impossible de charger les disponibilités.',
        onRetry: () => ref.invalidate(salonOverridesProvider(salonId)),
      ),
      data: (overrides) => ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Touchez un jour pour le fermer ou le rouvrir exceptionnellement.',
              style: AppTypography.body,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          WeekScheduleEditor(
            overrides: overrides,
            onDayTap: (date, existing) => showKynzaBottomSheet(
              context,
              builder: (_) => DayOverridePicker(
                date: date,
                salonId: salonId,
                existing: existing,
                onSave: (override) => ref
                    .read(availabilityNotifierProvider.notifier)
                    .save(override),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
