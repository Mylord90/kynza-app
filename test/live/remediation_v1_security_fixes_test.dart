@Tags(['live'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'live_test_env.dart';

/// Regression coverage for the 4 database-level security fixes applied to
/// `kynza-dr-scratch` during KYNZA Remediation v1, Phase 2
/// (docs/remediation/PHASE_2_SECURITY_FIXES.md). These fixes are drafted
/// migrations, not yet applied to production — this test only proves they
/// hold on the scratch project they were validated against, and guards
/// against a future change accidentally re-opening any of them there.
///
/// Not covered here (see PHASE_2_SECURITY_FIXES.md for the manual evidence
/// instead): `calculate-commission`'s cross-tenant fix (needs a disposable
/// booking + commission-rate fixture per run, judged too heavy for this
/// suite's existing lightweight conventions) and the cron-secret *success*
/// path for `run-scheduled-actions`/`schedule-reminders` (would require
/// committing the real `CRON_SECRET` value to source, which this test
/// deliberately does not do — only the *rejection* path, which needs no
/// secret, is asserted below).
void main() {
  late Map<String, dynamic> tenantA;

  setUpAll(() async {
    LiveTestEnv.requireEnv();
    tenantA = await LiveTestEnv.fetchTenant('a');
  });

  test(
    'staff_profiles.invitation_token is never returned to an unauthenticated caller',
    () async {
      final res = await httpGet(
        '/staff_profiles?select=id,invitation_token&invitation_accepted_at=is.null',
      );
      expect(res.statusCode, 200);
      final rows = jsonDecode(res.body) as List;
      expect(
        rows,
        isEmpty,
        reason:
            'staff_profiles_public_select was dropped in 20260704190000 — anon '
            'should see zero rows on the base table',
      );
    },
  );

  test(
    'v_staff_directory_public serves the public staff directory without invitation_token/phone',
    () async {
      final res = await httpGet(
        '/v_staff_directory_public?select=*&salon_id=eq.${tenantA['salonId']}',
      );
      expect(res.statusCode, 200);
      final rows = jsonDecode(res.body) as List;
      expect(
        rows,
        isNotEmpty,
        reason:
            'the replacement view must still serve real data to anon — a '
            'regression here (e.g. security_invoker reappearing) would '
            'silently break the client booking flow\'s practitioner picker',
      );
      for (final row in rows) {
        expect((row as Map<String, dynamic>).containsKey('invitation_token'), isFalse);
        expect(row.containsKey('phone'), isFalse);
        expect(row.containsKey('invited_by'), isFalse);
      }

      final badColumnRes = await httpGet(
        '/v_staff_directory_public?select=id,invitation_token',
      );
      expect(
        badColumnRes.statusCode,
        400,
        reason: 'invitation_token must not even exist as a column on the view',
      );
    },
  );

  test(
    'a staff member cannot reassign their own staff_profiles.salon_id to another salon',
    () async {
      final staffToken = tenantA['staffToken'] as String;
      final staffProfileId = tenantA['staffProfileId'] as String;
      const otherSalonId = '00000000-0000-0000-0000-000000000000';

      final res = await LiveTestEnv.userRest(
        'PATCH',
        '/staff_profiles?id=eq.$staffProfileId',
        staffToken,
        body: {'salon_id': otherSalonId},
      );

      expect(
        res.statusCode,
        403,
        reason:
            '20260704200000 pins salon_id in staff_own_profile_update\'s WITH '
            'CHECK the same way role already was',
      );

      // Confirm salon_id genuinely didn't change (belt-and-braces — a 403
      // should already guarantee this, but this is a security invariant
      // worth double-checking directly).
      final check = await LiveTestEnv.adminRest(
        'GET',
        '/staff_profiles?id=eq.$staffProfileId&select=salon_id',
      ) as List;
      expect(check.single['salon_id'], tenantA['salonId']);
    },
  );

  test(
    'create_default_document_templates rejects an unauthenticated caller',
    () async {
      final res = await httpPostRpc(
        'create_default_document_templates',
        {'p_salon_id': tenantA['salonId']},
      );
      expect(
        res.statusCode,
        400,
        reason:
            '20260704210000 requires owner/manager role via has_role() — an '
            'anon-only call (no user JWT) must be rejected, not silently '
            'seed templates for an arbitrary salon',
      );
    },
  );

  test(
    'run-scheduled-actions rejects a caller with only the public anon key',
    () async {
      final res = await LiveTestEnv.rawCall(
        'POST',
        '/functions/v1/run-scheduled-actions',
        headers: {
          'apikey': LiveTestEnv.anonKey!,
          'Authorization': 'Bearer ${LiveTestEnv.anonKey!}',
        },
      );
      expect(
        res.statusCode,
        403,
        reason:
            '20260704220000 + the Edge Function code patch require a '
            'matching X-Cron-Secret header the public anon key alone cannot '
            'supply',
      );
    },
  );

  test(
    'schedule-reminders rejects a caller with only the public anon key',
    () async {
      final res = await LiveTestEnv.rawCall(
        'POST',
        '/functions/v1/schedule-reminders',
        headers: {
          'apikey': LiveTestEnv.anonKey!,
          'Authorization': 'Bearer ${LiveTestEnv.anonKey!}',
        },
      );
      expect(res.statusCode, 403);
    },
  );
}

Future<dynamic> httpGet(String path) {
  return LiveTestEnv.rawCall(
    'GET',
    '/rest/v1$path',
    headers: {'apikey': LiveTestEnv.anonKey!},
  );
}

Future<dynamic> httpPostRpc(String fn, Map<String, dynamic> body) {
  return LiveTestEnv.rawCall(
    'POST',
    '/rest/v1/rpc/$fn',
    body: body,
    headers: {'apikey': LiveTestEnv.anonKey!, 'Content-Type': 'application/json'},
  );
}
