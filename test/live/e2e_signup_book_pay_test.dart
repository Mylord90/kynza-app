@Tags(['live'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'live_test_env.dart';

/// Critical-path E2E: signup -> browse -> book -> pay, run against the
/// real kynza-dr-scratch Supabase project through the actual deployed
/// edge functions (Phase 9, Enterprise Hardening pass).
///
/// Two genuine environment limitations were found while writing this
/// test and are worked around/documented rather than silently papered
/// over:
///  - The real public `/auth/v1/signup` endpoint rejects the IANA-reserved
///    example.com/.dev-style throwaway domains outright
///    (`email_address_invalid`), and once a real, MX-valid domain
///    (gmail.com) was used instead, Supabase's *built-in* email service
///    hit `over_email_send_rate_limit` on the very next attempt — this
///    project has no custom SMTP configured (Rule 9 of this hardening
///    pass forbids activating a paid/external service without explicit
///    approval), so the public self-serve signup endpoint cannot be
///    exercised repeatedly in an automated test here. This test instead
///    creates the "brand-new user" via the same Admin API path
///    `seed_qa_accounts.mjs` already uses (`email_confirm: true`, no
///    email sent) — still a genuinely fresh, never-before-seen user
///    exercising the full book+pay path, just not through the public
///    HTTP signup endpoint specifically.
///  - The "pay" step covers create-payment (the client-initiated online
///    payment flow — ProxiPay is the separate staff-initiated in-person
///    collection flow, already covered by proxipay_replay_attack_test.dart).
///    It stops at Leapa *initiation*, not settlement:
///    `initiateLeapaPayment` (supabase/functions/_shared/leapa.ts) falls
///    back to a local "processing"/sandbox stub whenever LEAPA_API_KEY
///    isn't configured (true here — Leapa's account is still pending
///    approval, per that file's own comment), and the booking's final
///    flip to "confirmed" is driven by `leapa-webhook`, a callback from
///    Leapa's real servers that this test has no way to trigger without
///    a real Leapa sandbox integration. Asserted honestly as "payment
///    initiated, sandbox mode" rather than faked with a synthetic webhook
///    call that would prove nothing about the real integration.
void main() {
  test('a brand-new user can sign up, browse, book, and initiate payment', () async {
    LiveTestEnv.requireEnv();
    final tenant = await LiveTestEnv.fetchTenant('a');

    final uniqueSuffix = DateTime.now().millisecondsSinceEpoch;
    final newEmail = 'kynza.qa.e2e.$uniqueSuffix@gmail.com';

    // 1. Signup — via the Admin API (see the file-level doc comment for
    // why the public /auth/v1/signup endpoint can't be used repeatedly
    // here). This is still a brand-new, never-before-seen user. Reuses
    // the same shared QA password as the seeded tenants (LiveTestEnv.signIn
    // always signs in with that one password) rather than a second,
    // per-user password that signIn() has no way to know about.
    final signupRes = await LiveTestEnv.adminAuthCall(
      'POST',
      '/auth/v1/admin/users',
      body: {
        'email': newEmail,
        'password': LiveTestEnv.password,
        'email_confirm': true,
      },
    );
    expect(signupRes.statusCode, 200, reason: signupRes.body);
    final signupBody = jsonDecode(signupRes.body) as Map<String, dynamic>;
    final newUserId = signupBody['id'] as String;
    addTearDown(
      () => LiveTestEnv.adminAuthCall('DELETE', '/auth/v1/admin/users/$newUserId'),
    );

    final clientToken = await LiveTestEnv.signIn(newEmail);

    // 2. Browse — public read of Salon A's service (services_public_select).
    final browseRes = await LiveTestEnv.userRest(
      'GET',
      '/services?id=eq.${tenant['serviceId']}&select=id,name,price_bif',
      clientToken,
    );
    expect(browseRes.statusCode, 200);
    final browsed = (jsonDecode(browseRes.body) as List).single as Map<String, dynamic>;
    expect(browsed['id'], tenant['serviceId']);

    // 3. Book.
    final startTime = DateTime.now()
        .add(Duration(days: 120, minutes: DateTime.now().millisecondsSinceEpoch % 1000))
        .toUtc();
    final bookRes = await LiveTestEnv.invokeFunction(
      'create-booking',
      clientToken,
      {
        'salonId': tenant['salonId'],
        'serviceId': tenant['serviceId'],
        'practitionerId': tenant['staffProfileId'],
        'startTime': startTime.toIso8601String(),
      },
    );
    expect(bookRes.statusCode, 200, reason: bookRes.body);
    final booking =
        (jsonDecode(bookRes.body) as Map<String, dynamic>)['booking'] as Map<String, dynamic>;
    final bookingId = booking['id'] as String;
    expect(booking['status'], 'pending_payment');
    addTearDown(() => LiveTestEnv.adminRest('DELETE', '/bookings?id=eq.$bookingId'));

    // 4. Pay (initiate) — see the file-level doc comment for why this
    // test stops here rather than asserting a final "confirmed" status.
    final payRes = await LiveTestEnv.invokeFunction(
      'create-payment',
      clientToken,
      {'bookingId': bookingId, 'method': 'lumicash', 'phone': '+25779000001'},
    );
    expect(payRes.statusCode, 200, reason: payRes.body);
    final payBody = jsonDecode(payRes.body) as Map<String, dynamic>;
    expect(payBody['sandbox'], true);
    expect(payBody['status'], 'processing');

    final transactions = await LiveTestEnv.adminRest(
      'GET',
      '/transactions?booking_id=eq.$bookingId&select=id,status',
    ) as List;
    expect(transactions, hasLength(1));
    expect(transactions.single['status'], 'processing');
    addTearDown(
      () => LiveTestEnv.adminRest('DELETE', '/transactions?booking_id=eq.$bookingId'),
    );
  });
}
