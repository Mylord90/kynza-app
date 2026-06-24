import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../core/models/salon_full_model.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/models/staff_profile_model.dart';
import '../../../../core/models/time_slot_model.dart';
import '../../../../core/providers/auth_providers.dart';
import 'booking_providers.dart';

part 'booking_flow_provider.freezed.dart';

@freezed
class BookingFlowState with _$BookingFlowState {
  const factory BookingFlowState({
    SalonFullModel? selectedSalon,
    ServiceModel? selectedService,
    StaffProfileModel? selectedPractitioner,
    DateTime? selectedDate,
    TimeSlot? selectedSlot,
    @Default(1) int currentStep,
    @Default(false) bool isLoading,
    String? error,
    BookingModel? createdBooking,
  }) = _BookingFlowState;
}

final bookingFlowProvider =
    NotifierProvider<BookingFlowNotifier, BookingFlowState>(
      BookingFlowNotifier.new,
    );

class BookingFlowNotifier extends Notifier<BookingFlowState> {
  @override
  BookingFlowState build() => const BookingFlowState();

  void selectSalon(SalonFullModel salon) {
    state = BookingFlowState(selectedSalon: salon, currentStep: 2);
  }

  void selectService(ServiceModel service) {
    state = state.copyWith(selectedService: service, currentStep: 3);
  }

  void selectPractitioner(StaffProfileModel? practitioner) {
    state = state.copyWith(selectedPractitioner: practitioner, currentStep: 4);
  }

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      selectedSlot: null,
      currentStep: 5,
    );
  }

  void selectSlot(TimeSlot slot) {
    state = state.copyWith(selectedSlot: slot, currentStep: 6);
  }

  /// Fast-Pass — pre-fills service + practitioner and jumps straight to
  /// the date step (kynza-booking-engine.md §8).
  void prefillFastPass({
    required SalonFullModel salon,
    required ServiceModel service,
    StaffProfileModel? practitioner,
  }) {
    state = BookingFlowState(
      selectedSalon: salon,
      selectedService: service,
      selectedPractitioner: practitioner,
      currentStep: 4,
    );
  }

  void reset() => state = const BookingFlowState();

  Future<void> submitBooking({String? notes}) async {
    final s = state;
    if (s.selectedSalon == null ||
        s.selectedService == null ||
        s.selectedSlot == null) {
      state = s.copyWith(error: 'Sélection incomplète.');
      return;
    }

    // When "N'importe quel praticien" was chosen, the merged slot itself
    // (TimeSlot.practitionerId) carries which staff member is actually
    // free at that time — bookings.practitioner_id is NOT NULL, so a
    // concrete practitioner must be resolved before submitting.
    final resolvedPractitionerId =
        s.selectedSlot!.practitionerId ?? s.selectedPractitioner?.id;
    if (resolvedPractitionerId == null) {
      state = s.copyWith(error: 'Aucun praticien disponible pour ce créneau.');
      return;
    }

    state = s.copyWith(isLoading: true, error: null);
    // Await the future rather than reading a possibly-still-loading cached
    // AsyncValue — on a slow connection the profile fetch may genuinely
    // not have resolved yet, which must not be confused with "logged out".
    final profile = await ref.read(currentUserProfileProvider.future);
    if (profile == null) {
      state = s.copyWith(isLoading: false, error: 'Session expirée.');
      return;
    }

    final draft = BookingModel(
      salonId: s.selectedSalon!.id,
      clientId: profile.id,
      practitionerId: resolvedPractitionerId,
      serviceId: s.selectedService!.id!,
      startTime: s.selectedSlot!.startTime,
      endTime: s.selectedSlot!.endTime,
      bufferEndTime: s.selectedSlot!.bufferEndTime,
      amountBif: s.selectedService!.priceBif,
      notes: notes,
    );

    try {
      final created = await ref
          .read(bookingRepositoryProvider)
          .createBooking(draft);
      state = state.copyWith(
        isLoading: false,
        createdBooking: created,
        currentStep: 7,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
