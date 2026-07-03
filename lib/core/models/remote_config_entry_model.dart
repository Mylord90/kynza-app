import 'package:freezed_annotation/freezed_annotation.dart';

part 'remote_config_entry_model.freezed.dart';
part 'remote_config_entry_model.g.dart';

@freezed
class RemoteConfigEntryModel with _$RemoteConfigEntryModel {
  const factory RemoteConfigEntryModel({
    required String id,
    required String key,
    required String category,
    required dynamic valueJson,
    required String valueType,
    String? description,
    required DateTime updatedAt,
    required DateTime createdAt,
  }) = _RemoteConfigEntryModel;

  factory RemoteConfigEntryModel.fromJson(Map<String, dynamic> json) =>
      _$RemoteConfigEntryModelFromJson(json);
}
