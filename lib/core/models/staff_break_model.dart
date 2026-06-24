import 'package:freezed_annotation/freezed_annotation.dart';

part 'staff_break_model.freezed.dart';
part 'staff_break_model.g.dart';

@freezed
class StaffBreakModel with _$StaffBreakModel {
  const factory StaffBreakModel({
    String? id,
    required String staffId,
    required String salonId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    @Default('Pause') String label,
    @Default(true) bool isRecurring,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _StaffBreakModel;

  factory StaffBreakModel.fromSupabase(Map<String, dynamic> json) =>
      StaffBreakModel.fromJson(json);

  factory StaffBreakModel.fromJson(Map<String, dynamic> json) =>
      _$StaffBreakModelFromJson(json);
}

extension StaffBreakModelX on StaffBreakModel {
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

  String get formattedRange =>
      '${startTime.substring(0, 5)} – ${endTime.substring(0, 5)}';
}
