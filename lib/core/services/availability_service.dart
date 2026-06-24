import '../enums/slot_availability.dart';
import '../models/time_slot_model.dart';
import 'supabase_service.dart';

/// Computes bookable time slots for a given service + practitioner + day.
/// See docs/ai/skills/kynza-booking-engine.md §5 — buffer_end_time blocks
/// the practitioner's planning but is never surfaced to the client (R18).
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

    final dayOfWeek = date.weekday - 1; // DateTime: 1=Mon..7=Sun → 0=Mon..6=Sun
    final dateOnly = DateTime(date.year, date.month, date.day);

    final overrideRow = await SupabaseService.from('availability_overrides')
        .select()
        .eq('salon_id', salonId)
        .eq('date', dateOnly.toIso8601String().substring(0, 10))
        .isFilter('deleted_at', null)
        .or('staff_id.eq.$practitionerId,staff_id.is.null')
        .order('staff_id', ascending: false) // staff-specific override first
        .limit(1)
        .maybeSingle();

    String? opensAt;
    String? closesAt;
    var isClosed = true;

    if (overrideRow != null) {
      isClosed = !(overrideRow['is_available'] as bool);
      opensAt = overrideRow['opens_at'] as String?;
      closesAt = overrideRow['closes_at'] as String?;
    } else {
      final hoursRow = await SupabaseService.from('working_hours')
          .select()
          .eq('salon_id', salonId)
          .eq('day_of_week', dayOfWeek)
          .isFilter('deleted_at', null)
          .maybeSingle();
      if (hoursRow != null) {
        isClosed = hoursRow['is_closed'] as bool;
        opensAt = hoursRow['opens_at'] as String?;
        closesAt = hoursRow['closes_at'] as String?;
      }
    }

    if (isClosed || opensAt == null || closesAt == null) return [];

    final dayStart = combineDateAndTime(dateOnly, opensAt);
    final dayEnd = combineDateAndTime(dateOnly, closesAt);

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

    return markRareIfFew(
      generateSlots(
        dayStart: dayStart,
        dayEnd: dayEnd,
        durationMin: durationMin,
        bufferMin: bufferMin,
        occupied: occupied,
        now: DateTime.now(),
      ),
    );
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
}
