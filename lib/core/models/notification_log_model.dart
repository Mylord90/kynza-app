import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_log_model.freezed.dart';
part 'notification_log_model.g.dart';

@freezed
class NotificationLogModel with _$NotificationLogModel {
  const factory NotificationLogModel({
    String? id,
    required String userId,
    String? salonId,
    required String eventType,
    required String channel,
    required String title,
    required String body,
    @Default(<String, dynamic>{}) Map<String, dynamic> data,
    @Default(false) bool isRead,
    DateTime? readAt,
    @Default(false) bool delivered,
    String? deliveryError,
    String? relatedBookingId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _NotificationLogModel;

  factory NotificationLogModel.fromSupabase(Map<String, dynamic> json) =>
      NotificationLogModel.fromJson(json);

  factory NotificationLogModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationLogModelFromJson(json);
}

extension NotificationLogModelX on NotificationLogModel {
  bool get isUnread => !isRead;
}
