import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/notification_log_model.dart';
import '../../../../core/models/notification_preferences_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../data/notification_read_cache.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(),
);

/// Cold-start-offline fix (Master Plan CP3, `BUSINESS_CONTINUITY_REPORT.md`)
/// — same cache-then-live pattern as booking_providers.dart's stream
/// providers: yields the last on-disk snapshot immediately, then forwards
/// every live emission, mirroring it back to disk.
final notificationsProvider = StreamProvider.autoDispose
    .family<List<NotificationLogModel>, int>((ref, limit) async* {
      final profile = ref.watch(currentUserProfileProvider).valueOrNull;
      if (profile == null) return;
      final cached = NotificationReadCache.get(profile.id);
      if (cached != null) yield cached.take(limit).toList();
      yield* ref
          .watch(notificationRepositoryProvider)
          .getNotifications(profile.id, limit: limit)
          .asyncMap((notifications) async {
            await NotificationReadCache.set(profile.id, notifications);
            return notifications;
          });
    });

final unreadCountProvider = StreamProvider.autoDispose((ref) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  if (profile == null) return Stream.value(0);
  return ref.watch(notificationRepositoryProvider).watchUnreadCount(profile.id);
});

final notificationPrefsProvider = FutureProvider.autoDispose((ref) async {
  final profile = await ref.watch(currentUserProfileProvider.future);
  if (profile == null) return null;
  return ref.read(notificationRepositoryProvider).getPreferences(profile.id);
});

final notificationNotifierProvider =
    AsyncNotifierProvider<NotificationNotifier, void>(NotificationNotifier.new);

class NotificationNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> markRead(String notifId) async {
    try {
      await ref.read(notificationRepositoryProvider).markAsRead(notifId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> markAllRead(String userId) async {
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead(userId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> delete(String notifId) async {
    try {
      await ref
          .read(notificationRepositoryProvider)
          .deleteNotification(notifId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updatePrefs(NotificationPreferencesModel prefs) async {
    state = const AsyncLoading();
    try {
      await ref.read(notificationRepositoryProvider).updatePreferences(prefs);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.invalidate(notificationPrefsProvider);
    }
  }

  Future<void> updateWhatsappPhone(String userId, String phone) async {
    try {
      await ref
          .read(notificationRepositoryProvider)
          .updateWhatsappPhone(userId, phone);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
