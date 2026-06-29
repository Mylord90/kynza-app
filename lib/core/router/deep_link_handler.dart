import 'route_names.dart';

/// Resolves a com.kynza.app:// deep link [Uri] (AndroidManifest.xml
/// intent-filters) to the matching go_router path. Custom schemes have no
/// path segment before a query string, so whatever immediately follows
/// `//` parses as the URI *host*, never as a go_router path — every
/// supported pattern is special-cased here instead of relying on
/// path-based route matching. Called from app_router.dart's redirect only
/// when `uri.host` is non-empty (in-app navigation never sets one).
abstract class DeepLinkHandler {
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
