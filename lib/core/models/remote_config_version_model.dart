import 'package:freezed_annotation/freezed_annotation.dart';

part 'remote_config_version_model.freezed.dart';
part 'remote_config_version_model.g.dart';

@freezed
class RemoteConfigVersionModel with _$RemoteConfigVersionModel {
  const factory RemoteConfigVersionModel({
    required String id,
    required String entryId,
    required int versionNumber,
    required dynamic valueJson,
    String? changeReason,
    required DateTime changedAt,
  }) = _RemoteConfigVersionModel;

  factory RemoteConfigVersionModel.fromJson(Map<String, dynamic> json) =>
      _$RemoteConfigVersionModelFromJson(json);
}
