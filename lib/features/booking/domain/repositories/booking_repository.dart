import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/booking_model.dart';

abstract class BookingRepository {
  Future<BookingModel> createBooking(BookingModel draft);
  Future<BookingModel> createWalkInBooking({
    required String salonId,
    required String serviceId,
    required String practitionerId,
    required DateTime startTime,
    required String guestFirstName,
    required String guestPhone,
    String? notes,
  });
  Future<BookingModel?> getById(String bookingId);
  Future<List<BookingModel>> getBookingsInRange(
    String salonId,
    DateTime start,
    DateTime end,
  );
  Future<List<BookingModel>> getPractitionerBookingsInRange(
    String practitionerId,
    DateTime start,
    DateTime end,
  );
  Stream<List<BookingModel>> getClientBookings(String clientId);
  Stream<List<BookingModel>> getSalonBookings(String salonId, DateTime date);
  Stream<List<BookingModel>> getPractitionerBookings(
    String practitionerId,
    DateTime date,
  );
  Future<BookingModel> updateStatus(String bookingId, BookingStatus status);
  Future<void> cancelBooking(String bookingId, String reason);
  Future<void> markNoShow(String bookingId);
  Future<void> markInProgress(String bookingId);
  Future<void> markCompleted(String bookingId);
}
