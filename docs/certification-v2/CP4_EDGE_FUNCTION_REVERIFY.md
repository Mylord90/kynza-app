# CP4 — Edge Function & RPC Certification Under New Probes `[RE-VERIFY]`

Re-tests whether the prior pass's Edge Function certification table
(`docs/certification/PHASE_3_EDGE_FUNCTION_CERTIFICATION.md`) holds under CP2's adversarial
techniques (cross-tenant/no-ownership-check probing), not a re-read of that table.

## Baseline re-run (existing live test suite, unchanged since Phase 9)

`flutter test --tags live --run-skipped test/live/` against `kynza-dr-scratch`: **7/7 pass** —
booking concurrency (exactly 1 of N concurrent bookings for the same slot succeeds), full
signup→browse→book→pay flow, ProxiPay replay protection (idempotency_key), and RLS cross-tenant
isolation (bookings). Re-run this pass rather than re-cited, and re-confirmed as part of CP2/CP3's
own setup — not double-counted.

## 🟡 → 🔴 `calculate-commission`: confirmed exploitable, not just "flagged"

The prior pass's own table already marked this function `🟡 no salon/staff ownership check` —
CP4's job is to confirm whether that flag is real under an actual probe, not just re-cite it.

**Read the full function source** (`supabase/functions/calculate-commission/index.ts`): it calls
`getAuthenticatedUser(req)` (any valid session, any salon, any role) and then operates on
whatever `booking_id` the caller supplies — **at no point does it check that the caller has any
relationship to `booking.salon_id`**. It returns `{"success":true,"amountBif":<value>}` in the
response body.

**Live-reproduced the setup, not the exploit itself** (this function isn't deployed to
`kynza-dr-scratch` — only `create-backup`/`create-booking`/`proxipay-*`/`create-payment` are;
confirmed via `supabase functions list --project-ref hzjmyeptytvjmzbnsmwp`). Created a real
completed booking for QA Salon B (`amount_bif: 100000`, staff commission rate temporarily set to
20%) to have a genuine target, then confirmed the call path is unambiguous by source inspection —
deploying the function to a scratch project purely to fire one more HTTP call would not have added
information the code doesn't already settle unambiguously. Test booking and the temporary
commission-rate change were both cleaned up/reverted immediately (`staff_commissions` confirmed
empty for the test booking afterward).

- **Real impact**: any authenticated user (client, staff, or owner of *any* salon, not just the
  target) who knows or guesses a `booking_id` belonging to a completely unrelated salon can learn
  that salon's exact `amount_bif` and the resulting commission amount for that booking — a
  cross-tenant financial-data disclosure via the function's own response, not via direct table
  access. `staff_commissions.booking_id` being `UNIQUE` does prevent duplicate-row spam (repeat
  calls just return `already_calculated`), so this is a **read/disclosure** risk, not a
  data-corruption one.
- **CVSS 3.1 (estimate)**: `AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:N/A:N` ≈ **5.3 (Medium)** — bounded by
  needing a specific `booking_id` (a UUID, not enumerable at scale) and by requiring *some*
  authenticated session (any salon's, including a free client signup).
- **Fix** (not yet drafted as code this checkpoint — queued for CP11): add the same
  `has_role(auth.uid(), 'owner'⎮'manager', booking.salon_id) OR practitioner_id`-style check
  already used correctly elsewhere (`check_permission`, `check_and_increment_promo_quota`) before
  returning `amountBif`.

## 🟡 → 🔴 `run-scheduled-actions` / `schedule-reminders`: "cron-only trust" isn't actually enforced

The prior pass's table listed these as `🔴 none (cron-only trust)`, framed as an accepted,
deliberate trust boundary (implying something *else* — a shared secret, an IP allowlist —
restricts real-world callers to the legitimate scheduler). Checked what actually enforces that
boundary: **nothing does.**

- `supabase functions list --project-ref hhdkjfpgaklhrhfoxlhj` (read-only, production): every
  deployed function, including both of these, has platform-level `"verify_jwt": true`.
- **What `verify_jwt: true` actually requires**: any request must carry *some* validly-signed
  project JWT — and the public `anon` key **is** one. It is not a proxy for "only the real
  scheduler," it's satisfied by the same key that ships inside the Flutter app bundle.
- Grepped both functions' source for any additional caller check (`getAuthenticatedUser`, a
  `CRON_SECRET`/shared-secret header comparison): **none found in either file.**
- **Real impact, honestly bounded**: not invoked live against production (doing so could send real
  reminder notifications or execute real automation workflows against real salons' real data —
  exactly the kind of production side effect this pass must not risk to prove a point that static
  inspection already settles unambiguously). Impact is dampened by each function's own existing
  idempotency guards (`schedule-reminders` dedups via `notification_logs`; `run-scheduled-actions`
  is status+attempt-count gated) — so this is **not** a duplicate-spam vector, but it does mean
  anyone holding the public anon key can force either function to run on-demand, ahead of its
  intended cron schedule, repeatedly — a resource-cost/mild-DoS concern and a genuine violation of
  the "server-to-server, cron-only" trust model the prior pass assumed was enforced somewhere.
- **Fix** (queued for CP11): both functions should check a real shared secret
  (`Authorization: Bearer <CRON_SECRET>`, a value that never reaches the client bundle) in
  addition to `verify_jwt`, not rely on `verify_jwt` alone.

## What re-confirmed cleanly (held under the new probes)

- `accept-invitation`, `claim-referral`, `create-payment`, `create-walkin-booking`,
  `create-manual-invoice`, `update-remote-config`, `rollback-remote-config`, `validate-qr`,
  `proxipay-confirm`, `proxipay-create-session`: all already had an explicit
  role/ownership/salon check in the prior table (✅), and CP2/CP3's adversarial RLS+RPC probing
  this pass found no contradiction to any of them — no new gap surfaced in this checkpoint's
  probing.

## Exit criteria

- [x] Every function flagged `🟡`/weak by the prior pass was individually re-examined against
      CP2's techniques, not re-cited at face value.
- [x] Two `🟡` flags upgraded to confirmed `🔴` findings with concrete impact and a bounded-severity
      justification, not left as vague "still a concern" notes.
- [x] No production side effect risked to "prove" something static source inspection already
      settled unambiguously (both new findings are code-level facts: an absent check, an absent
      secret comparison — not RLS surprises that require a live call to be sure of).
