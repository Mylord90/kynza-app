@Tags(['live'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'live_test_env.dart';

/// RLS cross-tenant access test — attempts to read another salon's data
/// and expects it to fail (return zero rows: PostgREST + RLS never leak a
/// 403, just an empty result set). Runs against the real kynza-dr-scratch
/// Supabase project using the QA tenants seeded by
/// `seed_qa_accounts.mjs` (Phase 9, Enterprise Hardening pass).
///
/// Policies under test (supabase/migrations/20260623240000_bookings_schema.sql):
///   CREATE POLICY "owner_manager_bookings" ON public.bookings
///     FOR ALL USING (has_role(auth.uid(), 'owner', salon_id) OR
///                     has_role(auth.uid(), 'manager', salon_id));
///   CREATE POLICY "staff_own_bookings_select" ON public.bookings
///     FOR SELECT USING (practitioner_id IN (SELECT id FROM staff_profiles
///                        WHERE user_id = auth.uid()));
void main() {
  late Map<String, dynamic> tenantA;
  late Map<String, dynamic> tenantB;
  late String seededBookingId;

  setUpAll(() async {
    LiveTestEnv.requireEnv();
    tenantA = await LiveTestEnv.fetchTenant('a');
    tenantB = await LiveTestEnv.fetchTenant('b');

    // Seed one confirmed booking directly in Salon A (service-role,
    // bypassing create-booking's own business rules — this test only
    // cares about RLS row visibility, not the booking flow itself).
    final startTime = DateTime.now().add(const Duration(days: 30)).toUtc();
    final endTime = startTime.add(const Duration(minutes: 30));
    final created = await LiveTestEnv.adminRest(
      'POST',
      '/bookings',
      body: {
        'salon_id': tenantA['salonId'],
        'client_id': tenantA['clientId'],
        'practitioner_id': tenantA['staffProfileId'],
        'service_id': tenantA['serviceId'],
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'buffer_end_time': endTime.toIso8601String(),
        'amount_bif': 15000,
        'status': 'confirmed',
      },
      extraHeaders: {'Prefer': 'return=representation'},
    ) as List;
    seededBookingId = created.single['id'] as String;
  });

  tearDownAll(() async {
    await LiveTestEnv.adminRest('DELETE', '/bookings?id=eq.$seededBookingId');
  });

  test('Salon A owner can see their own salon\'s booking', () async {
    final res = await LiveTestEnv.userRest(
      'GET',
      '/bookings?id=eq.$seededBookingId&select=id',
      tenantA['ownerToken'] as String,
    );
    expect(res.statusCode, 200);
    final rows = jsonDecode(res.body) as List;
    expect(rows, hasLength(1));
  });

  test('Salon B owner cannot see Salon A\'s booking (cross-tenant read blocked)', () async {
    final res = await LiveTestEnv.userRest(
      'GET',
      '/bookings?id=eq.$seededBookingId&select=id',
      tenantB['ownerToken'] as String,
    );
    expect(res.statusCode, 200); // RLS never 403s — it just filters rows out
    final rows = jsonDecode(res.body) as List;
    expect(rows, isEmpty);
  });

  test('Salon B staff cannot see Salon A\'s booking (cross-tenant read blocked)', () async {
    final res = await LiveTestEnv.userRest(
      'GET',
      '/bookings?id=eq.$seededBookingId&select=id',
      tenantB['staffToken'] as String,
    );
    expect(res.statusCode, 200);
    final rows = jsonDecode(res.body) as List;
    expect(rows, isEmpty);
  });

  // NOT tested here (2 real findings while writing this test, both
  // legitimate by design — not RLS bugs):
  //  - `services` are intentionally publicly readable
  //    (`services_public_select` USING (deleted_at IS NULL AND is_active =
  //    true), supabase/migrations/20260623210000_services_schema.sql) —
  //    any authenticated user can browse any salon's active services, for
  //    the discovery/booking flow.
  //  - `staff_profiles` are likewise intentionally publicly readable
  //    (`staff_profiles_public_select`,
  //    supabase/migrations/20260624050000_staff_profiles_public_select.sql)
  //    so a client can see which staff to pick when booking. That
  //    migration's own comment flags a separate, already-known,
  //    already-accepted caveat: `invitation_token` is exposed on this row
  //    to any reader too (RLS is row-level, not column-level) — not
  //    re-flagged as new here, just not silently re-tested as "blocked"
  //    when it demonstrably isn't, by design.
  // Financial data (`transactions`) has no such public carve-out — the
  // genuinely tenant-scoped target below.

  test('Salon B owner cannot see Salon A\'s transaction (financial data, cross-tenant read blocked)', () async {
    final txCreated = await LiveTestEnv.adminRest(
      'POST',
      '/transactions',
      body: {
        'salon_id': tenantA['salonId'],
        'booking_id': seededBookingId,
        'amount_bif': 15000,
        'method': 'lumicash',
        'status': 'processing',
        'idempotency_key': 'rls-test-$seededBookingId',
      },
      extraHeaders: {'Prefer': 'return=representation'},
    ) as List;
    final txId = txCreated.single['id'] as String;
    addTearDown(() => LiveTestEnv.adminRest('DELETE', '/transactions?id=eq.$txId'));

    final res = await LiveTestEnv.userRest(
      'GET',
      '/transactions?id=eq.$txId&select=id',
      tenantB['ownerToken'] as String,
    );
    expect(res.statusCode, 200);
    final rows = jsonDecode(res.body) as List;
    expect(rows, isEmpty);
  });
}
