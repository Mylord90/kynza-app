import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/models/working_hour_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../../salon/presentation/widgets/working_hours_editor.dart';

/// Standalone editor for the salon's default weekly hours — same
/// WorkingHoursEditor widget the onboarding wizard uses (salon_hours_step
/// .dart), wired here to update an already-existing salon instead of a
/// fresh draft.
class SalonHoursScreen extends ConsumerStatefulWidget {
  const SalonHoursScreen({super.key});

  @override
  ConsumerState<SalonHoursScreen> createState() => _SalonHoursScreenState();
}

class _SalonHoursScreenState extends ConsumerState<SalonHoursScreen> {
  List<WorkingHourModel>? _draft;

  @override
  Widget build(BuildContext context) {
    final salonAsync = ref.watch(salonNotifierProvider);
    final saving = salonAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Horaires du salon')),
      body: salonAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: KynzaSkeleton(height: 400),
        ),
        error: (_, __) => KynzaErrorState(
          message: "Impossible de charger les horaires.",
          onRetry: () => ref.invalidate(salonNotifierProvider),
        ),
        data: (salon) {
          if (salon == null) return const SizedBox.shrink();
          _draft ??= salon.workingHours.isEmpty
              ? List.generate(
                  7,
                  (day) => WorkingHourModel(
                    salonId: salon.id,
                    dayOfWeek: day,
                    isClosed: day == 6,
                    opensAt: '08:00:00',
                    closesAt: '18:00:00',
                  ),
                )
              : salon.workingHours;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              WorkingHoursEditor(
                hours: _draft!,
                onChanged: (updated) => setState(() => _draft = updated),
              ),
              const SizedBox(height: AppSpacing.xl),
              KynzaButton(
                label: 'Enregistrer',
                isLoading: saving,
                onPressed: () async {
                  await ref
                      .read(salonNotifierProvider.notifier)
                      .updateWorkingHours(_draft!);
                  if (context.mounted) {
                    showKynzaToast(
                      context,
                      message: 'Horaires enregistrés.',
                      level: ToastLevel.success,
                    );
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
