import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Certificate pinning for the Supabase API host — scaffolded and wired,
/// but OFF by default (Phase 5 of the Enterprise Hardening pass).
///
/// IMPORTANT — why this is inert until a human completes one more step:
/// Dart's `HttpClient.badCertificateCallback` is commonly (and wrongly)
/// used for "pinning" by checking the cert only inside that callback — but
/// that callback only fires for certs that already FAILED normal chain
/// validation. A real Supabase certificate passes normal validation, so
/// that callback would simply never run and the "pin check" inside it
/// would be dead code that looks like protection but provides none. The
/// correct approach used here instead is a restricted [SecurityContext]:
/// only the bytes in [pinnedCertificateDerBytes] are trusted at all, so a
/// connection to anything else — including a real CA-signed MITM cert for
/// the same hostname — fails outright, not just an unusual edge case.
///
/// [pinnedCertificateDerBytes] is empty by default on purpose: this
/// service has never had a verified capture of Supabase's actual
/// certificate run against it in this environment, and shipping a guessed
/// or stale byte string would immediately hard-fail every network call —
/// exactly the "bricks the app on a legitimate cert rotation" risk this
/// pass's own rules warn about. [isEnabled] must be flipped to `true` (via
/// [featureFlagEnabled] — see the kill-switch note below) only after:
///   1. Running [captureCurrentCertificateDer] once against the real
///      production Supabase host from a trusted machine/CI step.
///   2. Committing the resulting bytes into [pinnedCertificateDerBytes].
///   3. Verifying a full app smoke-test still succeeds against that pin.
/// Rotation procedure: repeat the same 3 steps before the currently-pinned
/// certificate expires (Supabase manages its own cert lifecycle; this
/// service has no visibility into the expiry date, so tracking the
/// rotation calendar is a manual ops responsibility, documented in
/// docs/security/SECURITY_AUDIT_V2.md).
abstract class CertificatePinningService {
  /// The kill switch. Even with real bytes configured, pinning stays off
  /// unless this is explicitly flipped — mirrors the `feature_flags`-style
  /// gating used elsewhere in this codebase (e.g. Google Maps in Phase 7),
  /// so a bad pin can be disabled instantly without a code change if this
  /// is later wired to a remote `feature_flags` row instead of a constant.
  static const bool featureFlagEnabled = false;

  /// DER-encoded bytes of the certificate(s) trusted for the Supabase
  /// host. Empty = pinning is a no-op regardless of [featureFlagEnabled].
  static const List<Uint8List> pinnedCertificateDerBytes = [];

  static bool get isActive =>
      featureFlagEnabled && pinnedCertificateDerBytes.isNotEmpty;

  /// Returns a pinned [http.Client] when active, otherwise the ordinary
  /// default client (normal system CA validation, no pinning) — callers
  /// never need to branch on [isActive] themselves.
  static http.Client createClient() {
    if (!isActive) return http.Client();

    final context = SecurityContext(withTrustedRoots: false);
    for (final der in pinnedCertificateDerBytes) {
      context.setTrustedCertificatesBytes(der);
    }
    final httpClient = HttpClient(context: context);
    return IOClient(httpClient);
  }

  /// Diagnostic-only helper for the one-time capture step described above
  /// — never called from app code, run manually (e.g. from a throwaway
  /// `main()` or a debug console) against the real production host to
  /// obtain the bytes for [pinnedCertificateDerBytes]. Returns null if no
  /// certificate could be captured (e.g. the callback never fires because
  /// [HttpClient] doesn't expose the peer certificate on a fully-trusted
  /// connection by default — capturing it reliably typically requires a
  /// one-off script using `SecurityContext.withTrustedRoots: false` plus
  /// `badCertificateCallback` returning true just for that inspection run,
  /// never in production code).
  static Future<Uint8List?> captureCurrentCertificateDer(String host) async {
    X509Certificate? captured;
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, _, _) {
        captured = cert;
        return true; // accept-and-record, diagnostic use only — never in app code
      };
    try {
      final request = await httpClient.getUrl(Uri.https(host, '/'));
      final response = await request.close();
      await response.drain<void>();
    } catch (_) {
      // Ignored — this is a best-effort diagnostic helper, not a
      // production code path with error-handling obligations.
    } finally {
      httpClient.close(force: true);
    }
    return captured?.der;
  }
}
