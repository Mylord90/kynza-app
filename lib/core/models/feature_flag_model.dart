import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_flag_model.freezed.dart';
part 'feature_flag_model.g.dart';

@freezed
class FeatureFlagModel with _$FeatureFlagModel {
  const factory FeatureFlagModel({
    required String id,
    required String key,
    required String name,
    String? description,
    required bool isEnabled,
    required int rolloutPercentage,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FeatureFlagModel;

  factory FeatureFlagModel.fromJson(Map<String, dynamic> json) =>
      _$FeatureFlagModelFromJson(json);
}
