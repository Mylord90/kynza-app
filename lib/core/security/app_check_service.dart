import 'app_check_feature_gate.dart';

/// Thin wrapper around Firebase App Check token attachment for sensitive
/// Edge Function calls (create-booking, proxipay-confirm — Phase 10,
/// Enterprise Hardening pass). Always returns an empty header map today:
/// `Env.appCheckEnabled` defaults to false, and even if it were flipped on,
/// no `firebase_app_check` SDK is wired up yet to actually produce a token
/// — deliberately not added as a dependency while unused, mirroring the
/// Google Maps scaffold's discipline (Phase 7) of not pulling in a heavy
/// native package until the feature is genuinely activated. See
/// docs/security/APP_CHECK_ARCHITECTURE.md for the exact activation
/// procedure (add the package, call `FirebaseAppCheck.instance.activate(...)`
/// in main.dart, replace the `return const {}` below with a real
/// `FirebaseAppCheck.instance.getToken()` call).
abstract class AppCheckService {
  static Future<Map<String, String>> headers() async {
    if (!AppCheckFeatureGate.isOptedIn) return const {};
    return const {};
  }
}
