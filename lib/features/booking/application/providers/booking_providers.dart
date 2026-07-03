import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../core/services/crash_reporting_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../loyalty/application/providers/loyalty_providers.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/repositories/booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepositoryImpl(),
);

final bookingByIdProvider = FutureProvider.family<BookingModel?, String>(
  (ref, bookingId) => ref.read(bookingRepositoryProvider).getById(bookingId),
);

final clientBookingsProvider =
    StreamProvider.family<List<BookingModel>, String>(
      (ref, clientId) =>
          ref.watch(bookingRepositoryProvider).getClientBookings(clientId),
    );

final salonBookingsProvider =
    StreamProvider.family<List<BookingModel>, (String salonId, DateTime date)>(
      (ref, params) => ref
          .watch(bookingRepositoryProvider)
          .getSalonBookings(params.$1, params.$2),
    );

final practitionerBookingsProvider =
    StreamProvider.family<
      List<BookingModel>,
      (String practitionerId, DateTime date)
    >(
      (ref, params) => ref
          .watch(bookingRepositoryProvider)
          .getPractitionerBookings(params.$1, params.$2),
    );

class SalonKpis {
  const SalonKpis({
    required this.revenueToday,
    required this.revenueWeek,
    required this.bookingsToday,
    required this.fillRate,
  });

  final int revenueToday;
  final int revenueWeek;
  final int bookingsToday;
  final double fillRate;
}

final salonKpisProvider = FutureProvider.family<SalonKpis, String>((
  ref,
  salonId,
) async {
  final repo = ref.read(bookingRepositoryProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));
  final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

  final todayBookings = await repo.getBookingsInRange(
    salonId,
    todayStart,
    todayEnd,
  );
  final weekBookings = await repo.getBookingsInRange(
    salonId,
    weekStart,
    todayEnd,
  );

  bool isRevenue(BookingModel b) =>
      b.status.name != 'cancelled' && b.status.name != 'noShow';

  final revenueToday = todayBookings
      .where(isRevenue)
      .fold(0, (sum, b) => sum + b.amountBif);
  final revenueWeek = weekBookings
      .where(isRevenue)
      .fold(0, (sum, b) => sum + b.amountBif);
  final activeToday = todayBookings.where(isRevenue).length;

  return SalonKpis(
    revenueToday: revenueToday,
    revenueWeek: revenueWeek,
    bookingsToday: activeToday,
    fillRate: activeToday == 0 ? 0 : (activeToday / 16).clamp(0, 1).toDouble(),
  );
});

final bookingActionNotifierProvider =
    AsyncNotifierProvider<BookingActionNotifier, void>(
      BookingActionNotifier.new,
    );

class BookingActionNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> updateStatus(String bookingId, BookingStatus status) async {
    try {
      await ref.read(bookingRepositoryProvider).updateStatus(bookingId, status);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> cancel(String bookingId, String reason) async {
    try {
      await ref
          .read(bookingRepositoryProvider)
          .cancelBooking(bookingId, reason);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Throws [AppException] on failure — callers show it directly rather
  /// than reading notifier state, same pattern as the other form screens.
  Future<BookingModel> createWalkIn({
    required String salonId,
    required String serviceId,
    required String practitionerId,
    required DateTime startTime,
    required String guestFirstName,
    required String guestPhone,
    String? notes,
  }) {
    return ref
        .read(bookingRepositoryProvider)
        .createWalkInBooking(
          salonId: salonId,
          serviceId: serviceId,
          practitionerId: practitionerId,
          startTime: startTime,
          guestFirstName: guestFirstName,
          guestPhone: guestPhone,
          notes: notes,
        );
  }

  /// R10 — no confirmation dialog ever wraps this call.
  Future<void> markInProgress(String bookingId) async {
    try {
      await ref.read(bookingRepositoryProvider).markInProgress(bookingId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> markCompleted(BookingModel booking) async {
    try {
      await ref.read(bookingRepositoryProvider).markCompleted(booking.id!);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
    await _awardLoyaltyStamp(booking);
    await _calculateCommission(booking);
  }

  /// Best-effort — a salon without an active loyalty program, or any
  /// failure here, must never block the booking from being marked done.
  Future<void> _awardLoyaltyStamp(BookingModel booking) async {
    try {
      final loyalty = ref.read(loyaltyRepositoryProvider);
      final card = await loyalty.getOrCreateCard(
        booking.salonId,
        booking.clientId,
      );
      await loyalty.addStamp(card.id!, bookingId: booking.id);
    } catch (e, st) {
      // Best-effort — see doc comment above. Logged as non-fatal so a
      // systemic failure (e.g. a broken RPC) is still visible in
      // Crashlytics, without blocking the booking completion flow.
      CrashReportingService.recordErrorForSalon(e, st, booking.salonId);
    }
  }

  /// Best-effort, same shape as [_awardLoyaltyStamp] — a practitioner with
  /// no commission_rate set (e.g. solo owner) must never block this.
  Future<void> _calculateCommission(BookingModel booking) async {
    try {
      await SupabaseService.client.functions.invoke(
        'calculate-commission',
        body: {'booking_id': booking.id},
      );
    } catch (e, st) {
      // Best-effort — see doc comment above. Non-fatal log only.
      CrashReportingService.recordErrorForSalon(e, st, booking.salonId);
    }
  }

  Future<void> markNoShow(String bookingId) async {
    try {
      await ref.read(bookingRepositoryProvider).markNoShow(bookingId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
