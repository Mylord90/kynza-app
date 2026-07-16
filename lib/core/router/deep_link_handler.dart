import 'package:go_router/go_router.dart';
import 'route_names.dart';

/// Resolves a com.kynza.app:// deep link [Uri] (AndroidManifest.xml
/// intent-filters) to the matching go_router path. Custom schemes have no
/// path segment before a query string, so whatever immediately follows
/// `//` parses as the URI *host*, never as a go_router path — every
/// supported pattern is special-cased here instead of relying on
/// path-based route matching. Called from app_router.dart's redirect only
/// when `uri.host` is non-empty (in-app navigation never sets one).
abstract class DeepLinkHandler {
  /// Cold-start FCM deep link (`RemoteMessage.data['deepLink']`), captured
  /// in main.dart right after `Firebase.initializeApp()`. This is always a
  /// plain path (e.g. `/booking/:id`, produced by send-notification), never
  /// a `com.kynza.app://` URI — [parseRoute] doesn't apply to it.
  ///
  /// In-memory only, deliberately not persisted to SessionService/Hive: a
  /// push tap is an ambient nudge (the notification stays in the tray, it's
  /// reproducible), unlike a pending invitation/referral token
  /// (`SessionService.getPendingInvitationToken`/`getPendingReferralToken`),
  /// which is a deliberate action worth surviving an app restart. If the
  /// user bounces off Login without signing in and relaunches later,
  /// replaying a stale target would be surprising, not helpful — so this
  /// field dies with the process, same as `getInitialMessage()` itself only
  /// ever reporting the launching notification once per real cold start.
  static String? _pendingIntent;

  static void capturePendingIntent(String? route) {
    if (route != null && route.isNotEmpty) _pendingIntent = route;
  }

  /// Returns and clears the captured intent in one call — the single call
  /// site (app_router.dart's redirect) is what makes the replay one-time by
  /// construction, not a separate "already consumed" flag to keep in sync.
  ///
  /// Validates [route] against [configuration] — the router's own
  /// registered route table (`RouteConfiguration.findMatch`, the same check
  /// go_router uses internally to decide whether to show its error screen)
  /// instead of a hand-maintained allowlist, so the routes declared in
  /// app_router.dart stay the single source of truth. Takes the
  /// `RouteConfiguration` directly rather than a `BuildContext` +
  /// `GoRouter.of(context)`: `GoRouter.configuration` is built synchronously
  /// in the constructor (not lazily on first widget build), so this stays
  /// testable in plain Dart against a throwaway `GoRouter`, no widget pump
  /// required. An unknown path (e.g. a stale payload from an older app
  /// version, or a route renamed since) is discarded silently: a missed
  /// notification is a non-event, a GoRouter error screen at cold start is
  /// an incident.
  static String? consumePendingIntent(RouteConfiguration configuration) {
    final route = _pendingIntent;
    if (route == null) return null;
    _pendingIntent = null;
    try {
      final match = configuration.findMatch(Uri.parse(route));
      return match.isError ? null : route;
    } catch (_) {
      return null;
    }
  }

  static String? parseRoute(Uri uri) {
    switch (uri.host) {
      case 'accept-invitation':
        return _withOptionalToken(RouteNames.acceptInvitation, uri);
      case 'accept-referral':
        return _withOptionalToken(RouteNames.acceptReferral, uri);
      case 'salon':
        final id = _firstSegment(uri);
        return id == null ? null : RouteNames.clientSalonDetailPath(id);
      case 'booking':
        final id = _firstSegment(uri);
        return id == null ? null : RouteNames.clientPaymentPath(id);
      default:
        return null;
    }
  }

  static String? _firstSegment(Uri uri) =>
      uri.pathSegments.isEmpty ? null : uri.pathSegments.first;

  static String _withOptionalToken(String route, Uri uri) {
    final token = uri.queryParameters['token'];
    return token != null ? '$route?token=$token' : route;
  }
}
