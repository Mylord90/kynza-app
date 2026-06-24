import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences_model.freezed.dart';
part 'notification_preferences_model.g.dart';

@freezed
class NotificationPreferencesModel with _$NotificationPreferencesModel {
  const factory NotificationPreferencesModel({
    String? id,
    required String userId,
    @Default(true) bool pushEnabled,
    @Default(true) bool whatsappEnabled,
    @Default(false) bool emailEnabled,
    @Default(true) bool bookingCreated,
    @Default(true) bool bookingConfirmed,
    @Default(true) bool bookingCancelled,
    @Default(true) bool bookingReminder24h,
    @Default(true) bool bookingReminder2h,
    @Default(true) bool staffEvents,
    @Default(false) bool marketing,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _NotificationPreferencesModel;

  factory NotificationPreferencesModel.fromSupabase(
    Map<String, dynamic> json,
  ) => NotificationPreferencesModel.fromJson(json);

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesModelFromJson(json);

  /// Used when no row exists yet for a user — every channel/event type
  /// defaults to the same value the DB column defaults would give.
  factory NotificationPreferencesModel.defaultsFor(String userId) =>
      NotificationPreferencesModel(userId: userId);
}

extension NotificationPreferencesModelX on NotificationPreferencesModel {
  /// Master toggle shown in settings — controls both reminder windows.
  bool get remindersEnabled => bookingReminder24h && bookingReminder2h;
}
