import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_version_check_model.freezed.dart';
part 'app_version_check_model.g.dart';

@freezed
class AppVersionCheckModel with _$AppVersionCheckModel {
  const factory AppVersionCheckModel({
    required bool updateRequired,
    required bool updateRecommended,
    String? latestVersionName,
    int? latestVersionCode,
    String? message,
  }) = _AppVersionCheckModel;

  factory AppVersionCheckModel.fromJson(Map<String, dynamic> json) =>
      _$AppVersionCheckModelFromJson(json);
}
