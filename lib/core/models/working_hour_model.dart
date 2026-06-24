import 'package:freezed_annotation/freezed_annotation.dart';

part 'working_hour_model.freezed.dart';
part 'working_hour_model.g.dart';

@freezed
class WorkingHourModel with _$WorkingHourModel {
  const factory WorkingHourModel({
    String? id,
    required String salonId,
    required int dayOfWeek,
    String? opensAt,
    String? closesAt,
    @Default(false) bool isClosed,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _WorkingHourModel;

  factory WorkingHourModel.fromSupabase(Map<String, dynamic> json) =>
      WorkingHourModel.fromJson(json);

  factory WorkingHourModel.fromJson(Map<String, dynamic> json) =>
      _$WorkingHourModelFromJson(json);
}

extension WorkingHourModelX on WorkingHourModel {
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
