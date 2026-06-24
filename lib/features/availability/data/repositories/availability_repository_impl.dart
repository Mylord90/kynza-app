import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/availability_exception_model.dart';
import '../../../../core/models/availability_override_model.dart';
import '../../../../core/models/staff_break_model.dart';
import '../../../../core/models/staff_working_hour_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/availability_repository.dart';

class AvailabilityRepositoryImpl implements AvailabilityRepository {
  static const _table = 'availability_overrides';
  static const _staffHoursTable = 'staff_working_hours';
  static const _breaksTable = 'staff_breaks';
  static const _exceptionsTable = 'availability_exceptions';

  @override
  Future<List<AvailabilityOverrideModel>> getOverrides(
    String salonId, {
    String? staffId,
  }) async {
    var query = SupabaseService.from(
      _table,
    ).select().eq('salon_id', salonId).isFilter('deleted_at', null);
    if (staffId != null) {
      query = query.eq('staff_id', staffId);
    }
    final rows = await query.order('date');
    return rows.map(AvailabilityOverrideModel.fromSupabase).toList();
  }

  @override
  Future<AvailabilityOverrideModel> upsertOverride(
    AvailabilityOverrideModel override,
  ) async {
    try {
      final dateOnly = override.date.toIso8601String().substring(0, 10);
      final row = await SupabaseService.from(_table)
          .upsert({
            if (override.id != null) 'id': override.id,
            'salon_id': override.salonId,
            'staff_id': override.staffId,
            'date': dateOnly,
            'is_available': override.isAvailable,
            'opens_at': override.opensAt,
            'closes_at': override.closesAt,
            'reason': override.reason,
          })
          .select()
          .single();
      return AvailabilityOverrideModel.fromSupabase(row);
    } catch (_) {
      throw const AppException("Impossible d'enregistrer cette exception.");
    }
  }

  @override
  Future<void> deleteOverride(String id) async {
    try {
      await SupabaseService.from(
        _table,
      ).update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
    } catch (_) {
      throw const AppException('Impossible de supprimer cette exception.');
    }
  }

  @override
  Future<List<StaffWorkingHourModel>> getStaffWorkingHours(
    String staffId,
    String salonId,
  ) async {
    final rows = await SupabaseService.from(_staffHoursTable)
        .select()
        .eq('staff_id', staffId)
        .isFilter('deleted_at', null)
        .order('day_of_week');
    return rows.map(StaffWorkingHourModel.fromSupabase).toList();
  }

  @override
  Future<void> updateStaffWorkingHours(
    String staffId,
    String salonId,
    List<StaffWorkingHourModel> hours,
  ) async {
    try {
      await SupabaseService.from(_staffHoursTable).upsert([
        for (final h in hours)
          {
            if (h.id != null) 'id': h.id,
            'staff_id': staffId,
            'salon_id': salonId,
            'day_of_week': h.dayOfWeek,
            'opens_at': h.opensAt,
            'closes_at': h.closesAt,
            'is_closed': h.isClosed,
          },
      ], onConflict: 'staff_id,day_of_week');
    } catch (_) {
      throw const AppException("Impossible d'enregistrer ces horaires.");
    }
  }

  @override
  Future<void> clearStaffWorkingHours(String staffId) async {
    try {
      await SupabaseService.from(_staffHoursTable)
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('staff_id', staffId);
    } catch (_) {
      throw const AppException('Impossible de réinitialiser ces horaires.');
    }
  }

  @override
  Future<List<StaffBreakModel>> getBreaks(String staffId) async {
    final rows = await SupabaseService.from(_breaksTable)
        .select()
        .eq('staff_id', staffId)
        .isFilter('deleted_at', null)
        .order('day_of_week')
        .order('start_time');
    return rows.map(StaffBreakModel.fromSupabase).toList();
  }

  @override
  Future<StaffBreakModel> addBreak(StaffBreakModel draft) async {
    try {
      final row = await SupabaseService.from(_breaksTable)
          .insert({
            'staff_id': draft.staffId,
            'salon_id': draft.salonId,
            'day_of_week': draft.dayOfWeek,
            'start_time': draft.startTime,
            'end_time': draft.endTime,
            'label': draft.label,
            'is_recurring': draft.isRecurring,
          })
          .select()
          .single();
      return StaffBreakModel.fromSupabase(row);
    } catch (_) {
      throw const AppException("Impossible d'ajouter cette pause.");
    }
  }

  @override
  Future<void> removeBreak(String id) async {
    try {
      await SupabaseService.from(
        _breaksTable,
      ).update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
    } catch (_) {
      throw const AppException('Impossible de supprimer cette pause.');
    }
  }

  @override
  Future<List<AvailabilityExceptionModel>> getExceptions(
    String salonId, {
    String? staffId,
  }) async {
    var query = SupabaseService.from(_exceptionsTable)
        .select()
        .eq('salon_id', salonId)
        .neq('exception_type', 'public_holiday')
        .isFilter('deleted_at', null);
    if (staffId != null) {
      query = query.eq('staff_id', staffId);
    }
    final rows = await query.order('start_date');
    return rows.map(AvailabilityExceptionModel.fromSupabase).toList();
  }

  @override
  Future<AvailabilityExceptionModel> addException(
    AvailabilityExceptionModel draft,
  ) async {
    try {
      final row = await SupabaseService.from(_exceptionsTable)
          .insert({
            'salon_id': draft.salonId,
            'staff_id': draft.staffId,
            'exception_type': draft.exceptionType,
            'start_date': draft.startDate.toIso8601String().substring(0, 10),
            'end_date': draft.endDate.toIso8601String().substring(0, 10),
            'label': draft.label,
            'opens_at': draft.opensAt,
            'closes_at': draft.closesAt,
            'is_closed': draft.isClosed,
          })
          .select()
          .single();
      return AvailabilityExceptionModel.fromSupabase(row);
    } catch (_) {
      throw const AppException("Impossible d'ajouter ce jour exceptionnel.");
    }
  }

  @override
  Future<void> removeException(String id) async {
    try {
      await SupabaseService.from(
        _exceptionsTable,
      ).update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
    } catch (_) {
      throw const AppException('Impossible de supprimer ce jour exceptionnel.');
    }
  }

  @override
  Future<List<AvailabilityExceptionModel>> getPublicHolidays(
    String salonId,
  ) async {
    final rows = await SupabaseService.from(_exceptionsTable)
        .select()
        .eq('salon_id', salonId)
        .eq('exception_type', 'public_holiday')
        .isFilter('deleted_at', null)
        .order('start_date');
    return rows.map(AvailabilityExceptionModel.fromSupabase).toList();
  }
}
