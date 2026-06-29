import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_group_model.freezed.dart';
part 'permission_group_model.g.dart';

@freezed
class PermissionGroupModel with _$PermissionGroupModel {
  const factory PermissionGroupModel({
    required String id,
    required String salonId,
    required String name,
    String? description,
    required String baseRole,
    @Default(false) bool isSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _PermissionGroupModel;

  factory PermissionGroupModel.fromJson(Map<String, dynamic> json) =>
      _$PermissionGroupModelFromJson(json);
}
