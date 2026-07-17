import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_version.dart';
import 'circuit_breaker.dart';
import 'crash_reporting_service.dart';
import 'supabase_service.dart';

/// FCM registration + foreground/background message routing.
/// Push notifications require the network by nature — never queued
/// client-side (kynza-offline-realtime.md §9).
class NotificationService {
  final _messaging = FirebaseMessaging.instance;

  /// CP2 (docs/enterprise-resilience/CIRCUIT_BREAKER_REPORT.md): the only
  /// caller (`auth_boot_gate.dart`) invokes this fire-and-forget — not
  /// awaited, no try/catch at the call site — so an uncaught exception
  /// here would only ever be caught by `main.dart`'s top-level
  /// `runZonedGuarded` zone handler: it wouldn't crash the app, but it also
  /// wouldn't reach any of the app's 5 UI states (CP1 finding). Caught here
  /// instead so a down/erroring FCM degrades to "push just isn't available
  /// this session" — never queued client-side (push has no offline
  /// meaning), but at least explicitly handled rather than relying solely
  /// on the global handler.
  Future<void> initialize() async {
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      final token = await DependencyCircuitBreakers.fcm.run<String?>(
        () => _messaging.getToken(),
        () async => null,
      );
      if (token != null) await saveFcmToken(token);
    } catch (e, st) {
      CrashReportingService.recordError(e, st);
    }
    _messaging.onTokenRefresh.listen(saveFcmToken);

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);
  }

  /// Phase 1b Étape 2 — writes to device_tokens (multi-device) via the
  /// SECURITY DEFINER upsert_device_token RPC instead of the old
  /// users.fcm_token column, which this stops writing entirely (it's
  /// deprecated, not dropped — Étape 3). kAppPlatform is real, measured
  /// (Platform.isAndroid/isIOS), never fabricated — device_tokens.platform
  /// is nullable specifically so a backfilled/never-measured row (NULL)
  /// stays distinguishable from a real one; writing a guessed value here
  /// would have destroyed that distinction on its very first use.
  ///
  /// Same best-effort shape as before — failures are still swallowed here,
  /// not fixed by this change. One new failure class exists that couldn't
  /// happen with a plain table UPDATE: the RPC itself being missing or
  /// signature-mismatched (e.g. an environment where this migration wasn't
  /// applied) surfaces as a distinct PostgREST error — still absorbed by
  /// the same fallback below, not surfaced to the user either way.
  Future<void> saveFcmToken(String token) async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) return;
    await DependencyCircuitBreakers.supabase.run<void>(
      () => SupabaseService.client.rpc(
        'upsert_device_token',
        params: {'_token': token, '_platform': kAppPlatform},
      ),
      () async {
        // Best-effort: Supabase down/erroring right now just means this
        // token save doesn't happen — the next onTokenRefresh or the next
        // app launch's initialize() retries naturally. Nothing to queue.
      },
    );
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
