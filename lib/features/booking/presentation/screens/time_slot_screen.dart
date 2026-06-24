import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/models/time_slot_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../availability/application/providers/availability_providers.dart';
import '../../application/providers/booking_flow_provider.dart';
import '../widgets/time_slot_grid.dart';
import 'booking_summary_screen.dart';

final _slotsForFlowProvider = FutureProvider.autoDispose<List<TimeSlot>>((
  ref,
) async {
  final state = ref.watch(bookingFlowProvider);
  if (state.selectedSalon == null ||
      state.selectedService == null ||
      state.selectedDate == null) {
    return [];
  }
  final service = ref.read(availabilityServiceProvider);
  final practitioner = state.selectedPractitioner;

  if (practitioner == null) {
    // "N'importe quel praticien" — merge every eligible staff member's
    // free slots (kynza-booking-engine.md §8 Fast-Pass also relies on
    // this union when no specific practitioner was pre-filled).
    return service.getAvailableSlotsAnyPractitioner(
      salonId: state.selectedSalon!.id,
      serviceId: state.selectedService!.id!,
      date: state.selectedDate!,
    );
  }

  return service.getAvailableSlots(
    salonId: state.selectedSalon!.id,
    serviceId: state.selectedService!.id!,
    practitionerId: practitioner.id!,
    date: state.selectedDate!,
  );
});

class TimeSlotScreen extends ConsumerWidget {
  const TimeSlotScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(bookingFlowProvider);
    final slotsAsync = ref.watch(_slotsForFlowProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Choisir un horaire')),
      body: slotsAsync.when(
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.4,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const KynzaSkeleton(height: 48),
        ),
        error: (_, __) => KynzaErrorState(
          message: 'Impossible de charger les créneaux.',
          onRetry: () => ref.invalidate(_slotsForFlowProvider),
        ),
        data: (slots) {
          if (slots.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: KynzaEmptyState(
                icon: Icons.event_busy_outlined,
                title: 'Aucun créneau disponible',
                subtitle: 'Essayez une autre date.',
                ctaLabel: 'Choisir une autre date',
                onCta: _noop,
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TimeSlotGrid(
              slots: slots,
              selected: flowState.selectedSlot,
              onSelected: (slot) {
                ref.read(bookingFlowProvider.notifier).selectSlot(slot);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BookingSummaryScreen(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

void _noop() {}
