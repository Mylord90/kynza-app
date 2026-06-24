import '../../../../core/models/notification_log_model.dart';
import '../../../../core/models/notification_preferences_model.dart';

abstract class NotificationRepository {
  Stream<List<NotificationLogModel>> getNotifications(
    String userId, {
    int limit = 20,
  });
  Stream<int> watchUnreadCount(String userId);
  Future<void> markAsRead(String notifId);
  Future<void> markAllAsRead(String userId);
  Future<void> deleteNotification(String notifId);
  Future<NotificationPreferencesModel> getPreferences(String userId);
  Future<void> updatePreferences(NotificationPreferencesModel prefs);
  Future<void> updateWhatsappPhone(String userId, String phone);
}
