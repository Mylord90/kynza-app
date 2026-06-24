import 'package:timezone/timezone.dart' as tz;
import '../enums/slot_availability.dart';
import '../models/time_slot_model.dart';
import 'supabase_service.dart';
import 'timezone_service.dart';

/// Computes bookable time slots for a given service + practitioner + day.
/// See docs/ai/skills/kynza-booking-engine.md §5 — buffer_end_time blocks
/// the practitioner's planning but is never surfaced to the client (R18).
///
/// Phase 2.2 / Module 3 extends this with staff-level working hours
/// (overriding the salon's), recurring staff breaks, and multi-day
/// availability_exceptions (vacations/closures/public holidays) — on top
/// of the existing single-day availability_overrides and salon-wide
/// working_hours from Phase 2. Precedence for a given day, most specific
/// first: single-day override → exception (staff-specific, then
/// salon-wide) → staff_working_hours → salon working_hours.
class AvailabilityService {
  Future<List<TimeSlot>> getAvailableSlots({
    required String salonId,
    required String serviceId,
    required String practitionerId,
    required DateTime date,
  }) async {
    final service = await SupabaseService.from(
      'services',
    ).select('duration_min, buffer_min').eq('id', serviceId).single();
    final durationMin = service['duration_min'] as int;
    final bufferMin = service['buffer_min'] as int;

    final dateOnly = DateTime(date.year, date.month, date.day);

    if (!await _isOpenForDay(
      salonId: salonId,
      practitionerId: practitionerId,
      date: dateOnly,
    )) {
      return [];
    }

    final hours = await _resolveOpeningHours(
      salonId: salonId,
      practitionerId: practitionerId,
      date: dateOnly,
    );
    if (hours == null) return [];

    final dayStart = _bujumburaWallClock(dateOnly, hours.opensAt);
    final dayEnd = _bujumburaWallClock(dateOnly, hours.closesAt);

    final bookingsRows = await SupabaseService.from('bookings')
        .select('start_time, buffer_end_time')
        .eq('practitioner_id', practitionerId)
        .gte('start_time', dayStart.toIso8601String())
        .lt('start_time', dayEnd.toIso8601String())
        .not('status', 'in', '(cancelled,no_show)')
        .isFilter('deleted_at', null);

    final occupied = bookingsRows
        .map(
          (r) => (
            start: DateTime.parse(r['start_time'] as String),
            bufferEnd: DateTime.parse(r['buffer_end_time'] as String),
          ),
        )
        .toList();

    occupied.addAll(
      await _breaksAsOccupiedRanges(
        practitionerId: practitionerId,
        date: dateOnly,
      ),
    );

    return markRareIfFew(
      generateSlots(
        dayStart: dayStart,
        dayEnd: dayEnd,
        durationMin: durationMin,
        bufferMin: bufferMin,
        occupied: occupied,
        now: TimeZoneService.nowLocal(),
      ),
    );
  }

  /// Closed if either a salon-wide or staff-specific availability_exception
  /// covers this date with is_closed=true. A single-day override is NOT
  /// consulted here — it's a more specific signal already folded into
  /// [_resolveOpeningHours], which can re-open a day this check would
  /// otherwise treat as closed via an exception (e.g. exceptionally
  /// opening on a public holiday).
  Future<bool> _isOpenForDay({
    required String salonId,
    required String practitionerId,
    required DateTime date,
  }) async {
    final overrideRow = await _matchingOverride(
      salonId: salonId,
      practitionerId: practitionerId,
      date: date,
    );
    if (overrideRow != null) return overrideRow['is_available'] as bool;

    final exception = await _matchingException(
      salonId: salonId,
      practitionerId: practitionerId,
      date: date,
    );
    if (exception != null) return !(exception['is_closed'] as bool);

    return true;
  }

  Future<Map<String, dynamic>?> _matchingOverride({
    required String salonId,
    required String practitionerId,
    required DateTime date,
  }) {
    return SupabaseService.from('availability_overrides')
        .select()
        .eq('salon_id', salonId)
        .eq('date', date.toIso8601String().substring(0, 10))
        .isFilter('deleted_at', null)
        .or('staff_id.eq.$practitionerId,staff_id.is.null')
        .order('staff_id', ascending: false) // staff-specific first
        .limit(1)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> _matchingException({
    required String salonId,
    required String practitionerId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await SupabaseService.from('availability_exceptions')
        .select()
        .eq('salon_id', salonId)
        .lte('start_date', dateStr)
        .gte('end_date', dateStr)
        .isFilter('deleted_at', null)
        .or('staff_id.eq.$practitionerId,staff_id.is.null');
    if (rows.isEmpty) return null;
    // Staff-specific exception wins over a salon-wide one for the same date.
    return rows.firstWhere(
      (r) => r['staff_id'] == practitionerId,
      orElse: () => rows.first,
    );
  }

  Future<({String opensAt, String closesAt})?> _resolveOpeningHours({
    required String salonId,
    required String practitionerId,
    required DateTime date,
  }) async {
    final dayOfWeek = date.weekday - 1; // DateTime: 1=Mon..7=Sun → 0=Mon..6=Sun

    final overrideRow = await _matchingOverride(
      salonId: salonId,
      practitionerId: practitionerId,
      date: date,
    );
    if (overrideRow != null) {
      final opensAt = overrideRow['opens_at'] as String?;
      final closesAt = overrideRow['closes_at'] as String?;
      if (overrideRow['is_available'] != true ||
          opensAt == null ||
          closesAt == null) {
        return null;
      }
      return (opensAt: opensAt, closesAt: closesAt);
    }

    final exception = await _matchingException(
      salonId: salonId,
      practitionerId: practitionerId,
      date: date,
    );
    if (exception != null) {
      if (exception['is_closed'] == true) return null;
      final opensAt = exception['opens_at'] as String?;
      final closesAt = exception['closes_at'] as String?;
      if (opensAt != null && closesAt != null) {
        return (opensAt: opensAt, closesAt: closesAt);
      }
      // Special opening with no explicit hours falls through to the
      // staff/salon default hours below.
    }

    final staffHoursRow = await SupabaseService.from('staff_working_hours')
        .select()
        .eq('staff_id', practitionerId)
        .eq('day_of_week', dayOfWeek)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (staffHoursRow != null) {
      if (staffHoursRow['is_closed'] == true) return null;
      final opensAt = staffHoursRow['opens_at'] as String?;
      final closesAt = staffHoursRow['closes_at'] as String?;
      if (opensAt == null || closesAt == null) return null;
      return (opensAt: opensAt, closesAt: closesAt);
    }

    final hoursRow = await SupabaseService.from('working_hours')
        .select()
        .eq('salon_id', salonId)
        .eq('day_of_week', dayOfWeek)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (hoursRow == null || hoursRow['is_closed'] == true) return null;
    final opensAt = hoursRow['opens_at'] as String?;
    final closesAt = hoursRow['closes_at'] as String?;
    if (opensAt == null || closesAt == null) return null;
    return (opensAt: opensAt, closesAt: closesAt);
  }

  /// Recurring weekly breaks reuse the exact same occupied-range shape as
  /// bookings — a break blocks slot generation identically to an existing
  /// appointment, with no separate code path in [generateSlots].
  Future<List<({DateTime start, DateTime bufferEnd})>> _breaksAsOccupiedRanges({
    required String practitionerId,
    required DateTime date,
  }) async {
    final dayOfWeek = date.weekday - 1;
    final rows = await SupabaseService.from('staff_breaks')
        .select('start_time, end_time')
        .eq('staff_id', practitionerId)
        .eq('day_of_week', dayOfWeek)
        .isFilter('deleted_at', null);

    return rows
        .map(
          (r) => (
            start: _bujumburaWallClock(date, r['start_time'] as String),
            bufferEnd: _bujumburaWallClock(date, r['end_time'] as String),
          ),
        )
        .toList();
  }

  /// Whether the salon is open at all on [date] — exceptions first, then
  /// the default weekly working_hours. Does not consider per-staff hours
  /// (a staff member closing early doesn't close the whole salon).
  Future<bool> isSalonOpen(String salonId, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final dateStr = dateOnly.toIso8601String().substring(0, 10);

    final exceptionRows = await SupabaseService.from('availability_exceptions')
        .select('is_closed')
        .eq('salon_id', salonId)
        .isFilter('staff_id', null)
        .lte('start_date', dateStr)
        .gte('end_date', dateStr)
        .isFilter('deleted_at', null)
        .limit(1);
    if (exceptionRows.isNotEmpty) {
      return !(exceptionRows.first['is_closed'] as bool);
    }

    final dayOfWeek = dateOnly.weekday - 1;
    final hoursRow = await SupabaseService.from('working_hours')
        .select('is_closed')
        .eq('salon_id', salonId)
        .eq('day_of_week', dayOfWeek)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (hoursRow == null) return true;
    return !(hoursRow['is_closed'] as bool);
  }

  /// Mirrors the UNIQUE(practitioner_id, start_time) + overlap guard the
  /// create-booking Edge Function enforces server-side — used client-side
  /// only for early UX feedback, never as the actual race-condition guard
  /// (kynza-booking-engine.md §2).
  Future<bool> hasConflict({
    required String practitionerId,
    required DateTime startTime,
    required DateTime endTime,
    String? excludeBookingId,
  }) async {
    var query = SupabaseService.from('bookings')
        .select('id')
        .eq('practitioner_id', practitionerId)
        .not('status', 'in', '(cancelled,no_show)')
        .isFilter('deleted_at', null)
        .lt('start_time', endTime.toIso8601String())
        .gt('buffer_end_time', startTime.toIso8601String());
    if (excludeBookingId != null) {
      query = query.neq('id', excludeBookingId);
    }
    final rows = await query.limit(1);
    return rows.isNotEmpty;
  }

  /// Pure slot-generation algorithm — no I/O, fully unit-testable.
  /// Steps a [durationMin]-wide window across [dayStart, dayEnd), excluding
  /// any window that overlaps an occupied range (booking start to its
  /// buffer_end_time) or that starts before [now].
  static List<TimeSlot> generateSlots({
    required DateTime dayStart,
    required DateTime dayEnd,
    required int durationMin,
    required int bufferMin,
    required List<({DateTime start, DateTime bufferEnd})> occupied,
    required DateTime now,
  }) {
    final slots = <TimeSlot>[];
    var cursor = dayStart;

    while (!cursor.isAfter(dayEnd.subtract(Duration(minutes: durationMin)))) {
      final slotEnd = cursor.add(Duration(minutes: durationMin));
      final slotBufferEnd = slotEnd.add(Duration(minutes: bufferMin));

      final overlapsBooking = occupied.any(
        (b) => cursor.isBefore(b.bufferEnd) && slotBufferEnd.isAfter(b.start),
      );
      final isPast = cursor.isBefore(now);

      if (!overlapsBooking && !isPast) {
        slots.add(
          TimeSlot(
            startTime: cursor,
            endTime: slotEnd,
            bufferEndTime: slotBufferEnd,
          ),
        );
      }
      cursor = cursor.add(Duration(minutes: durationMin));
    }

    return slots;
  }

  /// "N'importe quel praticien" — unions the free slots of every staff
  /// member who can perform this service. A merged slot at a given
  /// start_time is available as soon as ONE practitioner is free then;
  /// [TimeSlot.practitionerId] records which one will actually be
  /// assigned if the client picks it (bookings.practitioner_id is
  /// NOT NULL — there is no practitioner-less booking).
  Future<List<TimeSlot>> getAvailableSlotsAnyPractitioner({
    required String salonId,
    required String serviceId,
    required DateTime date,
  }) async {
    final practitionerIds = await _eligiblePractitionerIds(salonId, serviceId);
    if (practitionerIds.isEmpty) return [];

    final merged = <DateTime, TimeSlot>{};
    for (final practitionerId in practitionerIds) {
      final slots = await getAvailableSlots(
        salonId: salonId,
        serviceId: serviceId,
        practitionerId: practitionerId,
        date: date,
      );
      for (final slot in slots) {
        // First practitioner found for a given start_time wins the slot —
        // order is whatever _eligiblePractitionerIds returned (stable,
        // not meant to imply priority among staff).
        merged.putIfAbsent(
          slot.startTime,
          () => slot.copyWith(practitionerId: practitionerId),
        );
      }
    }

    final result = merged.values.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return markRareIfFew(result);
  }

  /// Staff explicitly assigned to the service (`staff_services`) if any
  /// exist; otherwise every active staff member of the salon, since a
  /// freshly-created service often has no per-staff assignment yet.
  Future<List<String>> _eligiblePractitionerIds(
    String salonId,
    String serviceId,
  ) async {
    final assigned = await SupabaseService.from('staff_services')
        .select('staff_id')
        .eq('salon_id', salonId)
        .eq('service_id', serviceId)
        .isFilter('deleted_at', null);

    if (assigned.isNotEmpty) {
      return assigned.map((r) => r['staff_id'] as String).toList();
    }

    final staff = await SupabaseService.from('staff_profiles')
        .select('id')
        .eq('salon_id', salonId)
        .eq('is_active', true)
        .isFilter('deleted_at', null);
    return staff.map((r) => r['id'] as String).toList();
  }

  /// "Dernière place !" nudge (kynza-booking-engine.md) — once 2 or fewer
  /// slots remain for the day, every one of them is flagged as rare.
  static List<TimeSlot> markRareIfFew(List<TimeSlot> slots) {
    if (slots.length > 2) return slots;
    return [
      for (final s in slots) s.copyWith(availability: SlotAvailability.rare),
    ];
  }

  /// Naive local combination — kept exactly as before for callers/tests
  /// that intentionally reason in device-local time rather than a named
  /// IANA zone. [_bujumburaWallClock] below is the timezone-correct
  /// equivalent used internally by [getAvailableSlots].
  static DateTime combineDateAndTime(DateTime date, String time) {
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// Same wall-clock combination as [combineDateAndTime] but anchored to
  /// Africa/Bujumbura (UTC+2, no DST) rather than whatever timezone the
  /// running device happens to be set to — the only way a `TIME` column
  /// like `working_hours.opens_at` can be turned into a correct absolute
  /// instant comparable with TIMESTAMPTZ booking rows (Module 3.B).
  static DateTime _bujumburaWallClock(DateTime date, String time) {
    final parts = time.split(':');
    return tz.TZDateTime(
      TimeZoneService.bujumbura,
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
}
