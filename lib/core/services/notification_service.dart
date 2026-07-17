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

  /// Phase 1b Étape 2, Item B — the other half of the leak Étape 1's
  /// upsert_device_token() closes on sign-*in*: without this, a signed-out
  /// device keeps showing the departing user's notifications until someone
  /// else signs in on it and triggers reassignment. Called from
  /// AuthNotifier.signOut() *before* the Supabase session is invalidated —
  /// the device_tokens own-row UPDATE policy (Étape 1) needs auth.uid() to
  /// still resolve to this user, same ordering requirement already
  /// documented there for the audit log call.
  ///
  /// Soft-delete only, scoped to this device's own token+user_id — no
  /// SECURITY DEFINER, no RPC: this is exactly the case ordinary RLS
  /// already handles correctly (Voie 2, Étape 1's design), unlike the
  /// cross-user reassignment upsert_device_token() exists for.
  ///
  /// Best-effort by design, same two circuit breakers already used above
  /// for the same two operations (FCM token fetch, Supabase write) — a
  /// failure here must never block sign-out itself; trapping a user
  /// mid-logout over a token cleanup would be worse than the leak this
  /// closes. A failed soft-delete just leaves this device's leak open for
  /// this session, exactly today's baseline, not worse — closed later by
  /// the next reassignment instead of by this cleanup.
  Future<void> revokeDeviceToken() async {
    final token = await DependencyCircuitBreakers.fcm.run<String?>(
      () => _messaging.getToken(),
      () async => null,
    );
    if (token == null) return;
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) return;
    await DependencyCircuitBreakers.supabase.run<void>(
      () => SupabaseService.from('device_tokens')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('token', token)
          .eq('user_id', userId),
      () async {
        // Best-effort: if this fails, the token stays active on this
        // device until someone else signs in and reassigns it (Étape 1) —
        // the same leak that existed before this item, not a new one.
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
