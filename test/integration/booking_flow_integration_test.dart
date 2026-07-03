import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/enums/app_enums.dart';
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

/// Widget-level "integration" tests exercise the booking flow's full state
/// machine (salon -> service -> practitioner -> date -> slot -> submit)
/// end-to-end through the real `BookingFlowNotifier`, a fake repository,
/// and a fake auth provider — following this repo's existing convention of
/// Riverpod provider-override fakes rather than a mocking framework
/// (Phase 9, Enterprise Hardening pass). It does not drive actual screen
/// widgets (GoRouter navigation between booking steps is out of scope for
/// this suite); it proves the collaborating units — notifier, repository,
/// auth — behave correctly together, which is what "end-to-end" means for
/// a step-driven wizard whose steps are pure state transitions, not routes.
class _FakeBookingRepository implements BookingRepository {
  _FakeBookingRepository({this.onCreateBooking});

  final Future<BookingModel> Function(BookingModel draft)? onCreateBooking;
  int createBookingCallCount = 0;

  @override
  Future<BookingModel> createBooking(BookingModel draft) async {
    createBookingCallCount++;
    if (onCreateBooking != null) return onCreateBooking!(draft);
    return draft.copyWith(id: 'booking-1');
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
  Future<BookingModel?> getById(String bookingId) =>
      throw UnimplementedError();

  @override
  Future<List<BookingModel>> getBookingsInRange(
    String salonId,
    DateTime start,
    DateTime end,
  ) => throw UnimplementedError();

  @override
  Stream<List<BookingModel>> getClientBookings(String clientId) =>
      throw UnimplementedError();

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

SalonFullModel _salon() => const SalonFullModel(id: 'salon-1', name: 'Salon');

ServiceModel _service() => const ServiceModel(
  id: 'service-1',
  salonId: 'salon-1',
  name: 'Coupe',
  category: 'hair',
  durationMin: 30,
  priceBif: 15000,
);

StaffProfileModel _practitioner() => const StaffProfileModel(
  id: 'staff-1',
  salonId: 'salon-1',
  displayName: 'Alice',
);

TimeSlot _slot({String? practitionerId}) => TimeSlot(
  startTime: DateTime(2026, 8, 1, 9),
  endTime: DateTime(2026, 8, 1, 9, 30),
  bufferEndTime: DateTime(2026, 8, 1, 9, 40),
  practitionerId: practitionerId,
);

UserProfile _client() => const UserProfile(id: 'client-1');

ProviderContainer _container({
  required BookingRepository repo,
  UserProfile? profile,
}) {
  final container = ProviderContainer(
    overrides: [
      bookingRepositoryProvider.overrideWithValue(repo),
      currentUserProfileProvider.overrideWith((ref) async => profile),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('Booking flow — full happy path', () {
    test('salon -> service -> practitioner -> date -> slot -> submit', () async {
      final repo = _FakeBookingRepository();
      final container = _container(repo: repo, profile: _client());
      final notifier = container.read(bookingFlowProvider.notifier);

      notifier.selectSalon(_salon());
      expect(container.read(bookingFlowProvider).currentStep, 2);

      notifier.selectService(_service());
      expect(container.read(bookingFlowProvider).currentStep, 3);

      notifier.selectPractitioner(_practitioner());
      expect(container.read(bookingFlowProvider).currentStep, 4);

      notifier.selectDate(DateTime(2026, 8, 1));
      expect(container.read(bookingFlowProvider).currentStep, 5);

      notifier.selectSlot(_slot());
      expect(container.read(bookingFlowProvider).currentStep, 6);

      await notifier.submitBooking();

      final state = container.read(bookingFlowProvider);
      expect(state.error, isNull);
      expect(state.currentStep, 7);
      expect(state.createdBooking?.id, 'booking-1');
      expect(repo.createBookingCallCount, 1);
    });

    test('"any practitioner" flow resolves practitionerId from the merged slot', () async {
      final repo = _FakeBookingRepository();
      final container = _container(repo: repo, profile: _client());
      final notifier = container.read(bookingFlowProvider.notifier);

      notifier.selectSalon(_salon());
      notifier.selectService(_service());
      notifier.selectPractitioner(null); // "N'importe quel praticien"
      notifier.selectDate(DateTime(2026, 8, 1));
      notifier.selectSlot(_slot(practitionerId: 'staff-resolved'));

      await notifier.submitBooking();

      final state = container.read(bookingFlowProvider);
      expect(state.error, isNull);
      expect(state.createdBooking?.practitionerId, 'staff-resolved');
    });
  });

  group('Booking flow — rejected paths', () {
    test('submit with no practitioner resolvable sets an error, does not call the repo', () async {
      final repo = _FakeBookingRepository();
      final container = _container(repo: repo, profile: _client());
      final notifier = container.read(bookingFlowProvider.notifier);

      notifier.selectSalon(_salon());
      notifier.selectService(_service());
      notifier.selectPractitioner(null);
      notifier.selectDate(DateTime(2026, 8, 1));
      notifier.selectSlot(_slot()); // no practitionerId on the slot either

      await notifier.submitBooking();

      final state = container.read(bookingFlowProvider);
      expect(state.error, isNotNull);
      expect(state.createdBooking, isNull);
      expect(repo.createBookingCallCount, 0);
    });

    test('submit with an incomplete selection sets an error, does not call the repo', () async {
      final repo = _FakeBookingRepository();
      final container = _container(repo: repo, profile: _client());
      final notifier = container.read(bookingFlowProvider.notifier);

      notifier.selectSalon(_salon());
      // service/practitioner/date/slot never selected

      await notifier.submitBooking();

      final state = container.read(bookingFlowProvider);
      expect(state.error, isNotNull);
      expect(repo.createBookingCallCount, 0);
    });

    test('submit with no session sets "Session expirée", does not call the repo', () async {
      final repo = _FakeBookingRepository();
      final container = _container(repo: repo, profile: null);
      final notifier = container.read(bookingFlowProvider.notifier);

      notifier.selectSalon(_salon());
      notifier.selectService(_service());
      notifier.selectPractitioner(_practitioner());
      notifier.selectDate(DateTime(2026, 8, 1));
      notifier.selectSlot(_slot());

      await notifier.submitBooking();

      final state = container.read(bookingFlowProvider);
      expect(state.error, 'Session expirée.');
      expect(repo.createBookingCallCount, 0);
    });

    test('the DB-level unique-slot constraint violation (409 slot_taken) surfaces as a state error', () async {
      final repo = _FakeBookingRepository(
        onCreateBooking: (draft) async =>
            throw Exception('slot_taken: 409 — practitioner_id, start_time already booked'),
      );
      final container = _container(repo: repo, profile: _client());
      final notifier = container.read(bookingFlowProvider.notifier);

      notifier.selectSalon(_salon());
      notifier.selectService(_service());
      notifier.selectPractitioner(_practitioner());
      notifier.selectDate(DateTime(2026, 8, 1));
      notifier.selectSlot(_slot(practitionerId: 'staff-1'));

      await notifier.submitBooking();

      final state = container.read(bookingFlowProvider);
      expect(state.error, contains('slot_taken'));
      expect(state.createdBooking, isNull);
      expect(state.isLoading, isFalse);
    });
  });
}
