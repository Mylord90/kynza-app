import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/notification_preferences_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(),
);

final notificationsProvider = StreamProvider.autoDispose((ref) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  if (profile == null) return const Stream.empty();
  return ref.watch(notificationRepositoryProvider).getNotifications(profile.id);
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
    state = await AsyncValue.guard(
      () => ref.read(notificationRepositoryProvider).markAsRead(notifId),
    );
  }

  Future<void> markAllRead(String userId) async {
    state = await AsyncValue.guard(
      () => ref.read(notificationRepositoryProvider).markAllAsRead(userId),
    );
  }

  Future<void> delete(String notifId) async {
    state = await AsyncValue.guard(
      () =>
          ref.read(notificationRepositoryProvider).deleteNotification(notifId),
    );
  }

  Future<void> updatePrefs(NotificationPreferencesModel prefs) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationRepositoryProvider).updatePreferences(prefs),
    );
    ref.invalidate(notificationPrefsProvider);
  }

  Future<void> updateWhatsappPhone(String userId, String phone) async {
    state = await AsyncValue.guard(
      () => ref
          .read(notificationRepositoryProvider)
          .updateWhatsappPhone(userId, phone),
    );
  }
}
