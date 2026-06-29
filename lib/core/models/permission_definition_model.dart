import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_definition_model.freezed.dart';
part 'permission_definition_model.g.dart';

@freezed
class PermissionDefinitionModel with _$PermissionDefinitionModel {
  const factory PermissionDefinitionModel({
    required String id,
    required String feature,
    required String action,
    @Default('') String resource,
    required String label,
    String? description,
    @Default('low') String riskLevel,
  }) = _PermissionDefinitionModel;

  factory PermissionDefinitionModel.fromJson(Map<String, dynamic> json) =>
      _$PermissionDefinitionModelFromJson(json);
}
