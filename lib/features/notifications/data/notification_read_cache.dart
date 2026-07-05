import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/models/notification_log_model.dart';

/// Last-known notification history snapshot per user — same convention as
/// [BookingReadCache]: `getNotifications` is a realtime `.stream()`, which
/// never errors on a cold start with no network (it just never emits), so
/// the fix happens at the provider level (see notification_providers.dart),
/// not via a catchable exception.
abstract class NotificationReadCache {
  static const boxName = 'kynza_notification_cache';

  static Box get _box => Hive.box(boxName);

  static List<NotificationLogModel>? get(String userId) {
    final raw = _box.get(userId);
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map(
          (r) => NotificationLogModel.fromJson(Map<String, dynamic>.from(r)),
        )
        .toList();
  }

  static Future<void> set(
    String userId,
    List<NotificationLogModel> notifications,
  ) => _box.put(userId, notifications.map((n) => n.toJson()).toList());

  static Future<void> clear() => _box.clear();
}
