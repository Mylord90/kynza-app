import '../../../../core/models/availability_exception_model.dart';
import '../../../../core/models/availability_override_model.dart';
import '../../../../core/models/staff_break_model.dart';
import '../../../../core/models/staff_working_hour_model.dart';

abstract class AvailabilityRepository {
  Future<List<AvailabilityOverrideModel>> getOverrides(
    String salonId, {
    String? staffId,
  });
  Future<AvailabilityOverrideModel> upsertOverride(
    AvailabilityOverrideModel override,
  );
  Future<void> deleteOverride(String id);

  /// Always returns exactly 7 rows (one per day_of_week, synthesizing an
  /// open default for any day without a saved row yet) — mirrors how
  /// SalonRepository.getOwnerSalon backfills working_hours.
  Future<List<StaffWorkingHourModel>> getStaffWorkingHours(
    String staffId,
    String salonId,
  );
  Future<void> updateStaffWorkingHours(
    String staffId,
    String salonId,
    List<StaffWorkingHourModel> hours,
  );

  /// Deletes every custom row for [staffId] — staff reverts to the
  /// salon's default working_hours.
  Future<void> clearStaffWorkingHours(String staffId);

  Future<List<StaffBreakModel>> getBreaks(String staffId);
  Future<StaffBreakModel> addBreak(StaffBreakModel draft);
  Future<void> removeBreak(String id);

  Future<List<AvailabilityExceptionModel>> getExceptions(
    String salonId, {
    String? staffId,
  });
  Future<AvailabilityExceptionModel> addException(
    AvailabilityExceptionModel draft,
  );
  Future<void> removeException(String id);
  Future<List<AvailabilityExceptionModel>> getPublicHolidays(String salonId);
}
