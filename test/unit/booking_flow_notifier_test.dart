import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/models/booking_model.dart';
import 'package:kynza/core/models/salon_full_model.dart';
import 'package:kynza/core/models/service_model.dart';
import 'package:kynza/core/models/staff_profile_model.dart';
import 'package:kynza/core/models/time_slot_model.dart';
import 'package:kynza/core/models/user_profile.dart';
import 'package:kynza/core/providers/auth_providers.dart';
import 'package:kynza/features/booking/application/providers/booking_flow_provider.dart';
import 'package:kynza/features/booking/application/providers/booking_providers.dart';
import 'package:kynza/features/booking/domain/repositories/booking_repository.dart';
import 'package:kynza/core/enums/app_enums.dart';

const _salon = SalonFullModel(id: 'salon-1', name: 'Salon Test');
const _service = ServiceModel(
  salonId: 'salon-1',
  id: 'service-1',
  name: 'Coupe',
  category: 'Coiffure Homme',
  durationMin: 30,
  priceBif: 10000,
);
const _staffA = StaffProfileModel(
  id: 'staff-a',
  salonId: 'salon-1',
  displayName: 'Alice',
);
final _slot = TimeSlot(
  startTime: DateTime(2026, 7, 1, 9),
  endTime: DateTime(2026, 7, 1, 9, 30),
  bufferEndTime: DateTime(2026, 7, 1, 9, 30),
);

/// Stubs every method except createBooking — the rest throw on purpose
/// so an accidental call in a future test fails loudly instead of
/// silently returning a default.
class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository({this.onCreate});

  final Future<BookingModel> Function(BookingModel draft)? onCreate;

  @override
  Future<BookingModel> createBooking(BookingModel draft) {
    if (onCreate == null) throw UnimplementedError();
    return onCreate!(draft);
  }

  @override
  Future<BookingModel> createWalkInBooking({
    required String salonId,
    required String serviceId,
    required String practitionerId,
    required DateTime startTime,
    required String guestFirstName,
    required String guestPhone,
    String? notes,
  }) => throw UnimplementedError();

  @override
  Future<void> cancelBooking(String bookingId, String reason) =>
      throw UnimplementedError();

  @override
  Stream<List<BookingModel>> getClientBookings(String clientId) =>
      throw UnimplementedError();

  @override
  Future<BookingModel?> getById(String bookingId) => throw UnimplementedError();

  @override
  Future<List<BookingModel>> getBookingsInRange(
    String salonId,
    DateTime start,
    DateTime end,
  ) => throw UnimplementedError();

  @override
  Future<List<BookingModel>> getPractitionerBookingsInRange(
    String practitionerId,
    DateTime start,
    DateTime end,
  ) => throw UnimplementedError();

  @override
  Stream<List<BookingModel>> getPractitionerBookings(
    String practitionerId,
    DateTime date,
  ) => throw UnimplementedError();

  @override
  Stream<List<BookingModel>> getSalonBookings(String salonId, DateTime date) =>
      throw UnimplementedError();

  @override
  Future<void> markCompleted(String bookingId) => throw UnimplementedError();

  @override
  Future<void> markInProgress(String bookingId) => throw UnimplementedError();

  @override
  Future<void> markNoShow(String bookingId) => throw UnimplementedError();

  @override
  Future<BookingModel> updateStatus(String bookingId, BookingStatus status) =>
      throw UnimplementedError();
}

ProviderContainer _makeContainer({
  UserProfile? profile,
  Future<BookingModel> Function(BookingModel draft)? onCreate,
}) {
  final container = ProviderContainer(
    overrides: [
      currentUserProfileProvider.overrideWith((ref) async => profile),
      bookingRepositoryProvider.overrideWith(
        (ref) => _FakeBookingRepository(onCreate: onCreate),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('BookingFlowNotifier — step transitions', () {
    test('selectSalon resets state and moves to step 2', () {
      final container = _makeContainer();
      final notifier = container.read(bookingFlowProvider.notifier);

      notifier.selectSalon(_salon);
      final state = container.read(bookingFlowProvider);

      expect(state.selectedSalon, _salon);
      expect(state.currentStep, 2);
      expect(state.selectedService, isNull);
    });

    test('selectService advances to step 3 and keeps the salon', () {
      final container = _makeContainer();
      final notifier = container.read(bookingFlowProvider.notifier);

      notifier.selectSalon(_salon);
      notifier.selectService(_service);
      final state = container.read(bookingFlowProvider);

      expect(state.selectedSalon, _salon);
      expect(state.selectedService, _service);
      expect(state.currentStep, 3);
    });

    test(
      'selectPractitioner(null) is valid ("any praticien") and advances to step 4',
      () {
        final container = _makeContainer();
        final notifier = container.read(bookingFlowProvider.notifier);

        notifier.selectSalon(_salon);
        notifier.selectService(_service);
        notifier.selectPractitioner(null);
        final state = container.read(bookingFlowProvider);

        expect(state.selectedPractitioner, isNull);
        expect(state.currentStep, 4);
      },
    );

    test(
      'selectDate clears any previously selected slot and advances to step 5',
      () {
        final container = _makeContainer();
        final notifier = container.read(bookingFlowProvider.notifier);

        notifier.selectSalon(_salon);
        notifier.selectService(_service);
        notifier.selectPractitioner(_staffA);
        notifier.selectSlot(_slot);
        expect(container.read(bookingFlowProvider).selectedSlot, isNotNull);

        notifier.selectDate(DateTime(2026, 7, 1));
        final state = container.read(bookingFlowProvider);

        expect(state.selectedSlot, isNull);
        expect(state.currentStep, 5);
      },
    );

    test('selectSlot advances to step 6', () {
      final container = _makeContainer();
      final notifier = container.read(bookingFlowProvider.notifier);

      notifier.selectSalon(_salon);
      notifier.selectSlot(_slot);
      final state = container.read(bookingFlowProvider);

      expect(state.selectedSlot, _slot);
      expect(state.currentStep, 6);
    });

    test(
      'prefillFastPass jumps straight to step 4 with service + practitioner set',
      () {
        final container = _makeContainer();
        final notifier = container.read(bookingFlowProvider.notifier);

        notifier.prefillFastPass(
          salon: _salon,
          service: _service,
          practitioner: _staffA,
        );
        final state = container.read(bookingFlowProvider);

        expect(state.selectedSalon, _salon);
        expect(state.selectedService, _service);
        expect(state.selectedPractitioner, _staffA);
        expect(state.currentStep, 4);
        expect(state.selectedSlot, isNull);
      },
    );

    test('reset clears everything back to the initial state', () {
      final container = _makeContainer();
      final notifier = container.read(bookingFlowProvider.notifier);

      notifier.selectSalon(_salon);
      notifier.selectService(_service);
      notifier.reset();
      final state = container.read(bookingFlowProvider);

      expect(state, const BookingFlowState());
    });
  });

  group('BookingFlowNotifier.submitBooking', () {
    test(
      'sets an error and never calls the repository when selection is incomplete',
      () async {
        final called = <BookingModel>[];
        final container = _makeContainer(
          profile: const UserProfile(id: 'client-1'),
          onCreate: (draft) async {
            called.add(draft);
            throw StateError('should not be called');
          },
        );
        final notifier = container.read(bookingFlowProvider.notifier);

        notifier.selectSalon(_salon);
        notifier.selectService(_service);
        // No slot selected yet.
        await notifier.submitBooking();

        final state = container.read(bookingFlowProvider);
        expect(state.error, isNotNull);
        expect(state.isLoading, isFalse);
        expect(called, isEmpty);
      },
    );

    test(
      'errors when neither a specific practitioner nor a merged-slot practitioner is available',
      () async {
        final container = _makeContainer(
          profile: const UserProfile(id: 'client-1'),
        );
        final notifier = container.read(bookingFlowProvider.notifier);

        notifier.selectSalon(_salon);
        notifier.selectService(_service);
        notifier.selectPractitioner(null); // "any praticien"
        // Slot from a single-practitioner query carries no practitionerId.
        notifier.selectSlot(_slot);

        await notifier.submitBooking();

        final state = container.read(bookingFlowProvider);
        expect(state.error, contains('praticien'));
      },
    );

    test(
      'resolves the practitioner from the merged slot when "any praticien" was picked',
      () async {
        BookingModel? sentDraft;
        final container = _makeContainer(
          profile: const UserProfile(id: 'client-1'),
          onCreate: (draft) async {
            sentDraft = draft;
            return draft.copyWith(
              id: 'booking-1',
              status: BookingStatus.confirmed,
            );
          },
        );
        final notifier = container.read(bookingFlowProvider.notifier);

        notifier.selectSalon(_salon);
        notifier.selectService(_service);
        notifier.selectPractitioner(null);
        // This slot came out of getAvailableSlotsAnyPractitioner — it knows
        // which staff member is actually free at this time.
        notifier.selectSlot(_slot.copyWith(practitionerId: 'staff-merged'));

        await notifier.submitBooking();

        expect(sentDraft?.practitionerId, 'staff-merged');
        final state = container.read(bookingFlowProvider);
        expect(state.createdBooking?.id, 'booking-1');
        expect(state.currentStep, 7);
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
      },
    );

    test(
      'a specific practitioner selection is used when the slot has no practitionerId',
      () async {
        BookingModel? sentDraft;
        final container = _makeContainer(
          profile: const UserProfile(id: 'client-1'),
          onCreate: (draft) async {
            sentDraft = draft;
            return draft.copyWith(id: 'booking-2');
          },
        );
        final notifier = container.read(bookingFlowProvider.notifier);

        notifier.selectSalon(_salon);
        notifier.selectService(_service);
        notifier.selectPractitioner(_staffA);
        notifier.selectSlot(_slot);

        await notifier.submitBooking();

        expect(sentDraft?.practitionerId, 'staff-a');
      },
    );

    test(
      'sets error and stops loading when the repository throws (e.g. slot_taken)',
      () async {
        final container = _makeContainer(
          profile: const UserProfile(id: 'client-1'),
          onCreate: (draft) async => throw Exception('slot_taken'),
        );
        final notifier = container.read(bookingFlowProvider.notifier);

        notifier.selectSalon(_salon);
        notifier.selectService(_service);
        notifier.selectPractitioner(_staffA);
        notifier.selectSlot(_slot);

        await notifier.submitBooking();

        final state = container.read(bookingFlowProvider);
        expect(state.isLoading, isFalse);
        expect(state.error, contains('slot_taken'));
        expect(state.createdBooking, isNull);
      },
    );

    test(
      'returns "Session expirée." when there is no authenticated profile',
      () async {
        final container = _makeContainer(profile: null);
        final notifier = container.read(bookingFlowProvider.notifier);

        notifier.selectSalon(_salon);
        notifier.selectService(_service);
        notifier.selectPractitioner(_staffA);
        notifier.selectSlot(_slot);

        await notifier.submitBooking();

        final state = container.read(bookingFlowProvider);
        expect(state.error, 'Session expirée.');
        expect(state.isLoading, isFalse);
      },
    );
  });
}
