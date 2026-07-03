@Tags(['live'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'live_test_env.dart';

/// Replay-attack test for the ProxiPay confirm flow — proves that
/// replaying the same `proxipay-confirm` call (e.g. a client double-tap,
/// or an attacker resubmitting a captured request) never double-charges.
/// Two independent guards are exercised together, exactly as they exist
/// in supabase/functions/proxipay-confirm/index.ts (confirmed by reading
/// the function before writing this test, not assumed):
///   1. `session.status === "confirmed"` short-circuits to
///      `{ alreadyConfirmed: true }` (200) instead of re-processing.
///   2. `transactions.idempotency_key` is unique per booking — a second
///      insert attempt (if it ever got that far) would fail cleanly too.
/// No real Leapa API call is ever made: `initiateLeapaPayment` (see
/// supabase/functions/_shared/leapa.ts) falls back to a local "processing"
/// stub whenever LEAPA_API_KEY isn't configured, which is the case on the
/// kynza-dr-scratch project used here — confirmed safe before running
/// this against a real, if non-production, Supabase project (Phase 9,
/// Enterprise Hardening pass).
void main() {
  test('replaying the same confirmed ProxiPay session never creates a second transaction', () async {
    LiveTestEnv.requireEnv();
    final tenant = await LiveTestEnv.fetchTenant('a');

    final startTime = DateTime.now()
        .add(Duration(days: 90, minutes: DateTime.now().millisecondsSinceEpoch % 1000))
        .toUtc();
    final endTime = startTime.add(const Duration(minutes: 30));
    final bookingCreated = await LiveTestEnv.adminRest(
      'POST',
      '/bookings',
      body: {
        'salon_id': tenant['salonId'],
        'client_id': tenant['clientId'],
        'practitioner_id': tenant['staffProfileId'],
        'service_id': tenant['serviceId'],
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'buffer_end_time': endTime.toIso8601String(),
        'amount_bif': 15000,
        'status': 'confirmed',
      },
      extraHeaders: {'Prefer': 'return=representation'},
    ) as List;
    final bookingId = bookingCreated.single['id'] as String;
    addTearDown(() => LiveTestEnv.adminRest('DELETE', '/bookings?id=eq.$bookingId'));

    final sessionRes = await LiveTestEnv.invokeFunction(
      'proxipay-create-session',
      tenant['staffToken'] as String,
      {'bookingId': bookingId},
    );
    expect(sessionRes.statusCode, 200, reason: sessionRes.body);
    final sessionId =
        (jsonDecode(sessionRes.body) as Map<String, dynamic>)['sessionId'] as String;
    addTearDown(
      () => LiveTestEnv.adminRest('DELETE', '/proxipay_sessions?id=eq.$sessionId'),
    );

    final firstConfirm = await LiveTestEnv.invokeFunction(
      'proxipay-confirm',
      tenant['clientToken'] as String,
      {'sessionId': sessionId, 'method': 'lumicash', 'phone': '+25779000000'},
    );
    expect(firstConfirm.statusCode, 200, reason: firstConfirm.body);
    final firstBody = jsonDecode(firstConfirm.body) as Map<String, dynamic>;
    expect(firstBody['alreadyConfirmed'], isNot(true));

    // The replay — same sessionId, same everything.
    final replayConfirm = await LiveTestEnv.invokeFunction(
      'proxipay-confirm',
      tenant['clientToken'] as String,
      {'sessionId': sessionId, 'method': 'lumicash', 'phone': '+25779000000'},
    );
    expect(replayConfirm.statusCode, 200, reason: replayConfirm.body);
    final replayBody = jsonDecode(replayConfirm.body) as Map<String, dynamic>;
    expect(replayBody['alreadyConfirmed'], true);

    final transactions = await LiveTestEnv.adminRest(
      'GET',
      '/transactions?booking_id=eq.$bookingId&select=id',
    ) as List;
    expect(
      transactions,
      hasLength(1),
      reason: 'the replayed confirm must never create a second transaction row',
    );

    await LiveTestEnv.adminRest(
      'DELETE',
      '/transactions?booking_id=eq.$bookingId',
    );
  });
}
