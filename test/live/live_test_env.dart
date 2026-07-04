import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Shared environment for the `live` tagged test suite (Phase 9, Enterprise
/// Hardening pass) — tests here make real HTTP calls against the
/// `kynza-dr-scratch` Supabase project (ref hzjmyeptytvjmzbnsmwp), which is
/// explicitly a non-production scratch project kept for exactly this
/// purpose (see reference_dr_scratch_supabase.md memory). They are tagged
/// `live` in dart_test.yaml with `skip: ...`, so a plain `flutter test`
/// never runs them — only an explicit `flutter test --tags live` does,
/// with the required env vars set. This keeps the phase's own zero-
/// regression baseline (`flutter test`, no flags) free of any live-network
/// dependency or flakiness.
///
/// Two QA tenants were seeded once via
/// `scripts (scratchpad)/seed_qa_accounts.mjs` — Salon A and Salon B, each
/// with an owner, a staff/practitioner, a client, and one bookable
/// service. Emails are fixed, non-secret fixture identifiers; only the
/// shared password and the service-role key (used here purely for
/// test-setup lookups, never for the assertions under test) are read from
/// env vars, never hardcoded.
class LiveTestEnv {
  static final projectRef = Platform.environment['KYNZA_LIVE_PROJECT_REF'] ??
      'hzjmyeptytvjmzbnsmwp';
  static final baseUrl = 'https://$projectRef.supabase.co';
  static final anonKey = Platform.environment['KYNZA_SCRATCH_ANON_KEY'];
  static final serviceRoleKey =
      Platform.environment['KYNZA_SCRATCH_SERVICE_ROLE_KEY'];
  static final password =
      Platform.environment['KYNZA_QA_PASSWORD'] ?? 'Kynza-QA-Test-2026!';

  static void requireEnv() {
    if (anonKey == null || serviceRoleKey == null) {
      throw StateError(
        'KYNZA_SCRATCH_ANON_KEY and KYNZA_SCRATCH_SERVICE_ROLE_KEY must be '
        'set to run the live test suite (flutter test --tags live).',
      );
    }
  }

  static Future<String> signIn(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/v1/token?grant_type=password'),
      headers: {'apikey': anonKey!, 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      throw StateError('sign-in failed for $email: ${res.statusCode} ${res.body}');
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['access_token'] as String;
  }

  /// Service-role REST call — bypasses RLS. Only used for test-setup
  /// lookups (resolving fixture IDs, creating a confirmed booking to seed
  /// a scenario) and cleanup, never for the actual security assertions.
  static Future<dynamic> adminRest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String> extraHeaders = const {},
  }) async {
    final uri = Uri.parse('$baseUrl/rest/v1$path');
    final headers = {
      'apikey': serviceRoleKey!,
      'Authorization': 'Bearer $serviceRoleKey',
      'Content-Type': 'application/json',
      ...extraHeaders,
    };
    final http.Response res;
    switch (method) {
      case 'GET':
        res = await http.get(uri, headers: headers);
        break;
      case 'POST':
        res = await http.post(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'PATCH':
        res = await http.patch(uri, headers: headers, body: jsonEncode(body));
        break;
      case 'DELETE':
        res = await http.delete(uri, headers: headers);
        break;
      default:
        throw ArgumentError('unsupported method $method');
    }
    if (res.statusCode >= 300) {
      throw StateError('$method $path -> ${res.statusCode}: ${res.body}');
    }
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }

  /// Raw call against any path under the project's base URL (not prefixed
  /// with /rest/v1) — used for /auth/v1/* endpoints that aren't PostgREST.
  static Future<http.Response> rawCall(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required Map<String, String> headers,
  }) {
    final uri = Uri.parse('$baseUrl$path');
    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: body == null ? null : jsonEncode(body));
      case 'PUT':
        return http.put(uri, headers: headers, body: body == null ? null : jsonEncode(body));
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        throw ArgumentError('unsupported method $method');
    }
  }

  /// Real public signup — POST /auth/v1/signup with the anon key, exactly
  /// what the app's own sign-up screen calls.
  static Future<http.Response> signUp(String email, String password) {
    return rawCall(
      'POST',
      '/auth/v1/signup',
      body: {'email': email, 'password': password},
      headers: {'apikey': anonKey!, 'Content-Type': 'application/json'},
    );
  }

  /// Admin Auth API call (service-role) — used for signup-confirmation
  /// fallback and end-of-test user cleanup, both outside PostgREST.
  static Future<http.Response> adminAuthCall(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) {
    return rawCall(
      method,
      path,
      body: body,
      headers: {
        'apikey': serviceRoleKey!,
        'Authorization': 'Bearer $serviceRoleKey',
        'Content-Type': 'application/json',
      },
    );
  }

  /// User-scoped REST call (RLS-respecting) — this is the call shape the
  /// actual assertions under test use.
  static Future<http.Response> userRest(
    String method,
    String path,
    String jwt, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl/rest/v1$path');
    final headers = {
      'apikey': anonKey!,
      'Authorization': 'Bearer $jwt',
      'Content-Type': 'application/json',
    };
    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: jsonEncode(body));
      case 'PATCH':
        return http.patch(uri, headers: headers, body: jsonEncode(body));
      default:
        throw ArgumentError('unsupported method $method');
    }
  }

  static Future<http.Response> invokeFunction(
    String name,
    String jwt,
    Map<String, dynamic> body,
  ) {
    return http.post(
      Uri.parse('$baseUrl/functions/v1/$name'),
      headers: {
        'apikey': anonKey!,
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  static Future<Map<String, dynamic>> fetchTenant(String label) async {
    final salons = await adminRest(
      'GET',
      '/salons?name=eq.QA Salon ${label.toUpperCase()}&select=id',
    ) as List;
    final salonId = salons.single['id'] as String;

    final services = await adminRest(
      'GET',
      '/services?salon_id=eq.$salonId&select=id',
    ) as List;
    final serviceId = services.single['id'] as String;

    final staffProfiles = await adminRest(
      'GET',
      '/staff_profiles?salon_id=eq.$salonId&select=id,user_id',
    ) as List;
    final staffProfileId = staffProfiles.single['id'] as String;

    final ownerToken = await signIn('kynza.qa.$label.owner@example.com');
    final staffToken = await signIn('kynza.qa.$label.staff@example.com');
    final clientToken = await signIn('kynza.qa.$label.client@example.com');

    final ownerRow = await adminRest(
      'GET',
      '/users?email=eq.kynza.qa.$label.owner@example.com&select=id',
    ) as List;
    final clientRow = await adminRest(
      'GET',
      '/users?email=eq.kynza.qa.$label.client@example.com&select=id',
    ) as List;

    return {
      'salonId': salonId,
      'serviceId': serviceId,
      'staffProfileId': staffProfileId,
      'ownerId': ownerRow.single['id'] as String,
      'clientId': clientRow.single['id'] as String,
      'ownerToken': ownerToken,
      'staffToken': staffToken,
      'clientToken': clientToken,
    };
  }
}
