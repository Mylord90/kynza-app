import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'supabase_service.dart';

/// FCM registration + foreground/background message routing.
/// Push notifications require the network by nature — never queued
/// client-side (kynza-offline-realtime.md §9).
class NotificationService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await _messaging.getToken();
    if (token != null) await saveFcmToken(token);
    _messaging.onTokenRefresh.listen(saveFcmToken);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);
  }

  Future<void> saveFcmToken(String token) async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) return;
    await SupabaseService.from(
      'users',
    ).update({'fcm_token': token}).eq('id', userId);
  }

  /// Overridden per-app via [onForegroundMessage] to surface
  /// KynzaNotificationBanner — kept here only for the FCM wiring itself.
  void Function(RemoteMessage message)? onForegroundMessage;
  void _onForegroundMessage(RemoteMessage message) =>
      onForegroundMessage?.call(message);

  void onNotificationTap(GoRouter router, RemoteMessage message) {
    final deepLink = message.data['deepLink'] as String?;
    if (deepLink != null) router.go(deepLink);
  }

  void Function(RemoteMessage message)? _tapHandler;
  void _onNotificationTap(RemoteMessage message) => _tapHandler?.call(message);
  set tapHandler(void Function(RemoteMessage message) handler) =>
      _tapHandler = handler;
}

/// Registered in main.dart via [FirebaseMessaging.onBackgroundMessage] —
/// must be a top-level function per the firebase_messaging contract.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally minimal: Supabase/FCM deliver the notification tray entry
  // automatically; no app state should be touched while in the background.
}
