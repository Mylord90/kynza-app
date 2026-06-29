import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log_model.freezed.dart';
part 'audit_log_model.g.dart';

@freezed
class AuditLogModel with _$AuditLogModel {
  const factory AuditLogModel({
    required String id,
    String? salonId,
    String? userId,
    String? userName,
    required String typeAction,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    DateTime? createdAt,
  }) = _AuditLogModel;

  factory AuditLogModel.fromSupabase(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AuditLogModel.fromJson({...json, 'user_name': user?['full_name']});
  }

  factory AuditLogModel.fromJson(Map<String, dynamic> json) =>
      _$AuditLogModelFromJson(json);
}

/// Maps `type_action` to one of the 4 audit-log filter chips — anything
/// outside booking/payment/staff falls under "settings" (catch-all), same
/// shape as the Phase 3B notification-center categorizer.
String auditLogCategoryFor(String typeAction) {
  if (typeAction.startsWith('booking_')) return 'booking';
  if (typeAction.startsWith('payment_') || typeAction.startsWith('refund_')) {
    return 'payment';
  }
  if (typeAction.startsWith('staff_')) return 'staff';
  return 'settings';
}
