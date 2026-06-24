import '../../../../core/enums/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/booking_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  static const _table = 'bookings';

  @override
  Future<BookingModel> createBooking(BookingModel draft) async {
    try {
      final res = await SupabaseService.client.functions.invoke(
        'create-booking',
        body: {
          'salonId': draft.salonId,
          'serviceId': draft.serviceId,
          'practitionerId': draft.practitionerId,
          'startTime': draft.startTime.toIso8601String(),
          'notes': draft.notes,
        },
      );
      if (res.status != 200) {
        final message = (res.data is Map)
            ? res.data['message'] as String?
            : null;
        throw AppException(
          message ??
              'Ce créneau vient d\'être réservé. Choisissez un autre horaire.',
        );
      }
      return BookingModel.fromSupabase(
        res.data['booking'] as Map<String, dynamic>,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException(
        'Impossible de créer la réservation. Réessayez.',
      );
    }
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
  }) async {
    try {
      final res = await SupabaseService.client.functions.invoke(
        'create-walkin-booking',
        body: {
          'salonId': salonId,
          'serviceId': serviceId,
          'practitionerId': practitionerId,
          'startTime': startTime.toIso8601String(),
          'guestFirstName': guestFirstName,
          'guestPhone': guestPhone,
          'notes': notes,
        },
      );
      if (res.status != 200) {
        final message = (res.data is Map) ? res.data['message'] as String? : null;
        throw AppException(message ?? "Ce créneau vient d'être réservé.");
      }
      return BookingModel.fromSupabase(res.data['booking'] as Map<String, dynamic>);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException('Impossible de créer ce rendez-vous. Réessayez.');
    }
  }

  @override
  Future<BookingModel?> getById(String bookingId) async {
    final row = await SupabaseService.from(
      _table,
    ).select().eq('id', bookingId).maybeSingle();
    if (row == null) return null;
    return BookingModel.fromSupabase(row);
  }

  @override
  Future<List<BookingModel>> getBookingsInRange(
    String salonId,
    DateTime start,
    DateTime end,
  ) async {
    final rows = await SupabaseService.from(_table)
        .select()
        .eq('salon_id', salonId)
        .gte('start_time', start.toIso8601String())
        .lt('start_time', end.toIso8601String())
        .isFilter('deleted_at', null);
    return rows.map(BookingModel.fromSupabase).toList();
  }

  @override
  Future<List<BookingModel>> getPractitionerBookingsInRange(
    String practitionerId,
    DateTime start,
    DateTime end,
  ) async {
    final rows = await SupabaseService.from(_table)
        .select()
        .eq('practitioner_id', practitionerId)
        .gte('start_time', start.toIso8601String())
        .lt('start_time', end.toIso8601String())
        .isFilter('deleted_at', null);
    return rows.map(BookingModel.fromSupabase).toList();
  }

  @override
  Stream<List<BookingModel>> getClientBookings(String clientId) {
    return SupabaseService.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('client_id', clientId)
        .map(
          (rows) =>
              rows
                  .where((r) => r['deleted_at'] == null)
                  .map(BookingModel.fromSupabase)
                  .toList()
                ..sort((a, b) => b.startTime.compareTo(a.startTime)),
        );
  }

  @override
  Stream<List<BookingModel>> getSalonBookings(String salonId, DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return SupabaseService.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('salon_id', salonId)
        .map(
          (rows) =>
              rows
                  .where((r) => r['deleted_at'] == null)
                  .map(BookingModel.fromSupabase)
                  .where(
                    (b) =>
                        b.startTime.isAfter(dayStart) &&
                        b.startTime.isBefore(dayEnd),
                  )
                  .toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime)),
        );
  }

  @override
  Stream<List<BookingModel>> getPractitionerBookings(
    String practitionerId,
    DateTime date,
  ) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return SupabaseService.client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('practitioner_id', practitionerId)
        .map(
          (rows) =>
              rows
                  .where((r) => r['deleted_at'] == null)
                  .map(BookingModel.fromSupabase)
                  .where(
                    (b) =>
                        b.startTime.isAfter(dayStart) &&
                        b.startTime.isBefore(dayEnd),
                  )
                  .toList()
                ..sort((a, b) => a.startTime.compareTo(b.startTime)),
        );
  }

  @override
  Future<BookingModel> updateStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      final row = await SupabaseService.from(_table)
          .update({'status': const BookingStatusConverter().toJson(status)})
          .eq('id', bookingId)
          .select()
          .single();
      return BookingModel.fromSupabase(row);
    } catch (_) {
      throw const AppException('Impossible de mettre à jour la réservation.');
    }
  }

  @override
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await SupabaseService.from(_table)
          .update({
            'status': 'cancelled',
            'cancellation_reason': reason,
            'cancelled_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);
    } catch (_) {
      throw const AppException("Impossible d'annuler cette réservation.");
    }
  }

  @override
  Future<void> markNoShow(String bookingId) async {
    try {
      await SupabaseService.client.functions.invoke(
        'mark-no-show',
        body: {'bookingId': bookingId},
      );
    } catch (_) {
      throw const AppException("Impossible de marquer l'absence.");
    }
  }

  @override
  Future<void> markInProgress(String bookingId) async {
    try {
      await SupabaseService.from(
        _table,
      ).update({'status': 'in_progress'}).eq('id', bookingId);
    } catch (_) {
      throw const AppException("Impossible de confirmer l'arrivée.");
    }
  }

  @override
  Future<void> markCompleted(String bookingId) async {
    try {
      await SupabaseService.from(_table)
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);
    } catch (_) {
      throw const AppException('Impossible de terminer cette prestation.');
    }
  }
}
