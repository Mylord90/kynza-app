import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/enums/slot_availability.dart';
import 'package:kynza/core/services/availability_service.dart';

void main() {
  group('AvailabilityService.combineDateAndTime', () {
    test('combines a date and an HH:MM:SS time string', () {
      final result = AvailabilityService.combineDateAndTime(
        DateTime(2026, 7, 1),
        '08:30:00',
      );
      expect(result, DateTime(2026, 7, 1, 8, 30));
    });
  });

  group('AvailabilityService.markRareIfFew', () {
    test('leaves slots untouched when more than 2 remain', () {
      final slots = AvailabilityService.generateSlots(
        dayStart: DateTime(2026, 7, 1, 8),
        dayEnd: DateTime(2026, 7, 1, 12),
        durationMin: 60,
        bufferMin: 0,
        occupied: const [],
        now: DateTime(2026, 6, 1),
      );
      final marked = AvailabilityService.markRareIfFew(slots);
      expect(marked, hasLength(4));
      expect(marked.every((s) => s.availability == SlotAvailability.normal), isTrue);
    });

    test('flags every slot as rare once 2 or fewer remain', () {
      final slots = AvailabilityService.generateSlots(
        dayStart: DateTime(2026, 7, 1, 8),
        dayEnd: DateTime(2026, 7, 1, 9, 30),
        durationMin: 60,
        bufferMin: 0,
        occupied: const [],
        now: DateTime(2026, 6, 1),
      );
      final marked = AvailabilityService.markRareIfFew(slots);
      expect(marked, hasLength(1));
      expect(marked.single.availability, SlotAvailability.rare);
    });

    test('an empty list stays empty', () {
      expect(AvailabilityService.markRareIfFew(const []), isEmpty);
    });
  });

  group('AvailabilityService.generateSlots', () {
    final farFuture = DateTime(2026, 1, 1); // "now" well before every window below

    test('steps a full day by duration_min with no buffer', () {
      final slots = AvailabilityService.generateSlots(
        dayStart: DateTime(2026, 7, 1, 8),
        dayEnd: DateTime(2026, 7, 1, 10),
        durationMin: 30,
        bufferMin: 0,
        occupied: const [],
        now: farFuture,
      );
      expect(slots.map((s) => s.startTime), [
        DateTime(2026, 7, 1, 8),
        DateTime(2026, 7, 1, 8, 30),
        DateTime(2026, 7, 1, 9),
        DateTime(2026, 7, 1, 9, 30),
      ]);
    });

    test('does not produce a slot that would spill past closing time', () {
      final slots = AvailabilityService.generateSlots(
        dayStart: DateTime(2026, 7, 1, 8),
        dayEnd: DateTime(2026, 7, 1, 9, 45),
        durationMin: 60,
        bufferMin: 0,
        occupied: const [],
        now: farFuture,
      );
      // 08:00-09:00 fits; 09:00-10:00 would spill past 09:45 and is excluded.
      expect(slots, hasLength(1));
      expect(slots.single.startTime, DateTime(2026, 7, 1, 8));
    });

    test('excludes a slot that overlaps an existing booking', () {
      final slots = AvailabilityService.generateSlots(
        dayStart: DateTime(2026, 7, 1, 8),
        dayEnd: DateTime(2026, 7, 1, 11),
        durationMin: 60,
        bufferMin: 0,
        occupied: [(start: DateTime(2026, 7, 1, 9), bufferEnd: DateTime(2026, 7, 1, 10))],
        now: farFuture,
      );
      expect(slots.map((s) => s.startTime), [
        DateTime(2026, 7, 1, 8),
        DateTime(2026, 7, 1, 10),
      ]);
    });

    test('buffer_min after a booking blocks the immediately following slot too', () {
      // 09:00-10:00 booking + 15min buffer occupies the practitioner until
      // 10:15, so the 10:00 slot must also be excluded (kynza-booking-engine
      // §5 — buffer_end_time blocks planning even though it's invisible to
      // the client, R18).
      final slots = AvailabilityService.generateSlots(
        dayStart: DateTime(2026, 7, 1, 8),
        dayEnd: DateTime(2026, 7, 1, 12),
        durationMin: 60,
        bufferMin: 0,
        occupied: [(start: DateTime(2026, 7, 1, 9), bufferEnd: DateTime(2026, 7, 1, 10, 15))],
        now: farFuture,
      );
      expect(slots.map((s) => s.startTime), [
        DateTime(2026, 7, 1, 8),
        DateTime(2026, 7, 1, 11),
      ]);
    });

    test('candidate slots are independent of each other — only confirmed '
        'bookings (via the occupied list) exclude a slot, not other '
        'not-yet-chosen candidates', () {
      // duration 30 + buffer 15: each candidate slot's own buffer only
      // matters once IT is booked (becoming part of `occupied` for the
      // next query) — it must not preemptively hide its sibling slot.
      final slots = AvailabilityService.generateSlots(
        dayStart: DateTime(2026, 7, 1, 9),
        dayEnd: DateTime(2026, 7, 1, 10),
        durationMin: 30,
        bufferMin: 15,
        occupied: const [],
        now: farFuture,
      );
      expect(slots.map((s) => s.startTime), [
        DateTime(2026, 7, 1, 9),
        DateTime(2026, 7, 1, 9, 30),
      ]);
    });

    test('excludes slots that start in the past relative to "now"', () {
      final slots = AvailabilityService.generateSlots(
        dayStart: DateTime(2026, 7, 1, 8),
        dayEnd: DateTime(2026, 7, 1, 11),
        durationMin: 60,
        bufferMin: 0,
        occupied: const [],
        now: DateTime(2026, 7, 1, 9, 30), // mid-way through the day
      );
      expect(slots.map((s) => s.startTime), [DateTime(2026, 7, 1, 10)]);
    });

    test('returns an empty list when the window is shorter than one slot', () {
      final slots = AvailabilityService.generateSlots(
        dayStart: DateTime(2026, 7, 1, 8),
        dayEnd: DateTime(2026, 7, 1, 8, 20),
        durationMin: 30,
        bufferMin: 0,
        occupied: const [],
        now: farFuture,
      );
      expect(slots, isEmpty);
    });

    test('a fully booked day with back-to-back bookings yields no slots', () {
      final slots = AvailabilityService.generateSlots(
        dayStart: DateTime(2026, 7, 1, 8),
        dayEnd: DateTime(2026, 7, 1, 10),
        durationMin: 60,
        bufferMin: 0,
        occupied: [
          (start: DateTime(2026, 7, 1, 8), bufferEnd: DateTime(2026, 7, 1, 9)),
          (start: DateTime(2026, 7, 1, 9), bufferEnd: DateTime(2026, 7, 1, 10)),
        ],
        now: farFuture,
      );
      expect(slots, isEmpty);
    });
  });
}
