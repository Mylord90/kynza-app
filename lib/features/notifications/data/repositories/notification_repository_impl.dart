import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/notification_log_model.dart';
import '../../../../core/models/notification_preferences_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  static const _logsTable = 'notification_logs';
  static const _prefsTable = 'notification_preferences';

  @override
  Stream<List<NotificationLogModel>> getNotifications(
    String userId, {
    int limit = 20,
  }) {
    return SupabaseService.client
        .from(_logsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map(
          (rows) =>
              rows
                  .where(
                    (r) => r['deleted_at'] == null && r['channel'] == 'in_app',
                  )
                  .map(NotificationLogModel.fromSupabase)
                  .toList()
                ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!)),
        )
        .map((list) => list.take(limit).toList());
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return SupabaseService.client
        .from(_logsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map(
          (rows) => rows
              .where(
                (r) =>
                    r['deleted_at'] == null &&
                    r['channel'] == 'in_app' &&
                    r['is_read'] == false,
              )
              .length,
        );
  }

  @override
  Future<void> markAsRead(String notifId) async {
    try {
      await SupabaseService.from(_logsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notifId);
    } catch (_) {
      throw const AppException('Impossible de marquer comme lu.');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await SupabaseService.from(_logsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (_) {
      throw const AppException('Impossible de tout marquer comme lu.');
    }
  }

  @override
  Future<void> deleteNotification(String notifId) async {
    try {
      await SupabaseService.from(_logsTable)
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', notifId);
    } catch (_) {
      throw const AppException('Impossible de supprimer cette notification.');
    }
  }

  @override
  Future<NotificationPreferencesModel> getPreferences(String userId) async {
    final row = await SupabaseService.from(
      _prefsTable,
    ).select().eq('user_id', userId).maybeSingle();
    if (row == null) {
      return NotificationPreferencesModel.defaultsFor(userId);
    }
    return NotificationPreferencesModel.fromSupabase(row);
  }

  @override
  Future<void> updatePreferences(NotificationPreferencesModel prefs) async {
    try {
      await SupabaseService.from(_prefsTable).upsert({
        if (prefs.id != null) 'id': prefs.id,
        'user_id': prefs.userId,
        'push_enabled': prefs.pushEnabled,
        'whatsapp_enabled': prefs.whatsappEnabled,
        'email_enabled': prefs.emailEnabled,
        'booking_created': prefs.bookingCreated,
        'booking_confirmed': prefs.bookingConfirmed,
        'booking_cancelled': prefs.bookingCancelled,
        'booking_reminder_24h': prefs.bookingReminder24h,
        'booking_reminder_2h': prefs.bookingReminder2h,
        'staff_events': prefs.staffEvents,
        'marketing': prefs.marketing,
      }, onConflict: 'user_id');
    } catch (_) {
      throw const AppException("Impossible d'enregistrer vos préférences.");
    }
  }

  @override
  Future<void> updateWhatsappPhone(String userId, String phone) async {
    try {
      await SupabaseService.from('users')
          .update({
            'whatsapp_phone': phone,
            'whatsapp_opt_in': true,
            'whatsapp_opt_in_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (_) {
      throw const AppException('Impossible d\'enregistrer ce numéro WhatsApp.');
    }
  }
}
