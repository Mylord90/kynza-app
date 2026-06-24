import 'package:freezed_annotation/freezed_annotation.dart';
import '../enums/slot_availability.dart';

part 'time_slot_model.freezed.dart';

@freezed
class TimeSlot with _$TimeSlot {
  const factory TimeSlot({
    required DateTime startTime,
    required DateTime endTime,
    required DateTime bufferEndTime,
    @Default(true) bool isAvailable,
    @Default(SlotAvailability.normal) SlotAvailability availability,
    /// Set only when this slot came from the "any practitioner" merge
    /// (kynza-booking-engine.md has no concept of a practitioner-less
    /// booking — bookings.practitioner_id is NOT NULL) — records which
    /// concrete staff member will be assigned if the client picks it.
    String? practitionerId,
  }) = _TimeSlot;
}
