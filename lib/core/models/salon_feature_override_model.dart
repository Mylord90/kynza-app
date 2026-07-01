import 'package:freezed_annotation/freezed_annotation.dart';

part 'salon_feature_override_model.freezed.dart';
part 'salon_feature_override_model.g.dart';

@freezed
class SalonFeatureOverrideModel with _$SalonFeatureOverrideModel {
  const factory SalonFeatureOverrideModel({
    required String id,
    required String salonId,
    required String flagKey,
    required bool isEnabled,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SalonFeatureOverrideModel;

  factory SalonFeatureOverrideModel.fromJson(Map<String, dynamic> json) =>
      _$SalonFeatureOverrideModelFromJson(json);
}
