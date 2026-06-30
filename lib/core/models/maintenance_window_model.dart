import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_window_model.freezed.dart';
part 'maintenance_window_model.g.dart';

@freezed
class MaintenanceWindowModel with _$MaintenanceWindowModel {
  const factory MaintenanceWindowModel({
    required bool isActive,
    String? title,
    String? message,
    DateTime? endsAt,
  }) = _MaintenanceWindowModel;

  factory MaintenanceWindowModel.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceWindowModelFromJson(json);
}