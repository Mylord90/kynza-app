import 'package:freezed_annotation/freezed_annotation.dart';

part 'staff_working_hour_model.freezed.dart';
part 'staff_working_hour_model.g.dart';

/// Per-staff override of [WorkingHourModel] for a given day of week —
/// when present for a (staffId, dayOfWeek) pair, it takes priority over
/// the salon's default working_hours (kynza-booking-engine.md extension,
/// Phase 2.2 / Module 3).
@freezed
class StaffWorkingHourModel with _$StaffWorkingHourModel {
  const factory StaffWorkingHourModel({
    String? id,
    required String staffId,
    required String salonId,
    required int dayOfWeek,
    String? opensAt,
    String? closesAt,
    @Default(false) bool isClosed,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _StaffWorkingHourModel;

  factory StaffWorkingHourModel.fromSupabase(Map<String, dynamic> json) =>
      StaffWorkingHourModel.fromJson(json);

  factory StaffWorkingHourModel.fromJson(Map<String, dynamic> json) =>
      _$StaffWorkingHourModelFromJson(json);
}

extension StaffWorkingHourModelX on StaffWorkingHourModel {
  static const _dayLabels = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  String get dayLabel => _dayLabels[dayOfWeek];

  String get formattedRange {
    if (isClosed || opensAt == null || closesAt == null) return 'Fermé';
    return '${opensAt!.substring(0, 5)} – ${closesAt!.substring(0, 5)}';
  }
}
