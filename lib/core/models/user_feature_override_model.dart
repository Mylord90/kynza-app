import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_feature_override_model.freezed.dart';
part 'user_feature_override_model.g.dart';

@freezed
class UserFeatureOverrideModel with _$UserFeatureOverrideModel {
  const factory UserFeatureOverrideModel({
    required String id,
    required String salonId,
    required String userId,
    required String flagKey,
    required bool isEnabled,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserFeatureOverrideModel;

  factory UserFeatureOverrideModel.fromJson(Map<String, dynamic> json) =>
      _$UserFeatureOverrideModelFromJson(json);
}
