import 'package:freezed_annotation/freezed_annotation.dart';

part 'role_feature_override_model.freezed.dart';
part 'role_feature_override_model.g.dart';

@freezed
class RoleFeatureOverrideModel with _$RoleFeatureOverrideModel {
  const factory RoleFeatureOverrideModel({
    required String id,
    required String salonId,
    required String role,
    required String flagKey,
    required bool isEnabled,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _RoleFeatureOverrideModel;

  factory RoleFeatureOverrideModel.fromJson(Map<String, dynamic> json) =>
      _$RoleFeatureOverrideModelFromJson(json);
}
