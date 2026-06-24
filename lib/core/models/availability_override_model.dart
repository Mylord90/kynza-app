import 'package:freezed_annotation/freezed_annotation.dart';

part 'availability_override_model.freezed.dart';
part 'availability_override_model.g.dart';

@freezed
class AvailabilityOverrideModel with _$AvailabilityOverrideModel {
  const factory AvailabilityOverrideModel({
    String? id,
    required String salonId,
    String? staffId,
    required DateTime date,
    @Default(false) bool isAvailable,
    String? opensAt,
    String? closesAt,
    String? reason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _AvailabilityOverrideModel;

  factory AvailabilityOverrideModel.fromSupabase(Map<String, dynamic> json) =>
      AvailabilityOverrideModel.fromJson(json);

  factory AvailabilityOverrideModel.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityOverrideModelFromJson(json);
}
