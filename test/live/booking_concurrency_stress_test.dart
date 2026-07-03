@Tags(['live'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'live_test_env.dart';

/// Stress test: fires N concurrent `create-booking` requests at the same
/// (practitioner_id, start_time) slot and proves the DB-level
/// UNIQUE(practitioner_id, start_time) constraint
/// (supabase/migrations/20260623240000_bookings_schema.sql, confirmed by
/// research before writing this test) rejects every request but exactly
/// one — the double-booking race condition must be caught server-side,
/// not just by client-side slot-picker UI. Runs against the real
/// kynza-dr-scratch Supabase project (Phase 9, Enterprise Hardening pass).
void main() {
  test('N concurrent bookings for the same slot: exactly 1 succeeds, the rest get 409 slot_taken', () async {
    LiveTestEnv.requireEnv();
    final tenant = await LiveTestEnv.fetchTenant('a');

    // A fresh slot every run (now + a random-ish offset derived from the
    // current time) so repeated runs never collide with a previous run's
    // leftover booking.
    final startTime = DateTime.now()
        .add(Duration(days: 60, minutes: DateTime.now().millisecondsSinceEpoch % 1000))
        .toUtc();

    const concurrency = 10;
    final responses = await Future.wait(
      List.generate(
        concurrency,
        (_) => LiveTestEnv.invokeFunction(
          'create-booking',
          tenant['clientToken'] as String,
          {
            'salonId': tenant['salonId'],
            'serviceId': tenant['serviceId'],
            'practitionerId': tenant['staffProfileId'],
            'startTime': startTime.toIso8601String(),
          },
        ),
      ),
    );

    final statusCodes = responses.map((r) => r.statusCode).toList()..sort();
    final successes = statusCodes.where((c) => c == 200).length;
    final conflicts = statusCodes.where((c) => c == 409).length;

    expect(
      successes,
      1,
      reason: 'exactly one concurrent request must win the slot; got status codes $statusCodes',
    );
    expect(conflicts, concurrency - 1);

    for (final res in responses) {
      if (res.statusCode == 409) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        expect(body['error'], 'slot_taken');
      }
    }

    // Clean up the one booking that was actually created.
    final winner = responses.firstWhere((r) => r.statusCode == 200);
    final bookingId =
        (jsonDecode(winner.body) as Map<String, dynamic>)['booking']['id'] as String;
    await LiveTestEnv.adminRest('DELETE', '/bookings?id=eq.$bookingId');
  });
}
