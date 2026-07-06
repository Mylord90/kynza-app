# Checkpoint 2 — Safe Redeployment

**Date**: 2026-07-06. **Scope**: redeploy each of the three fixes identified in CP1, one at a
time, independently — with an explicit stop-roll back-report rule if any single one fails. All
three succeeded; **zero rollback was needed.**

## Pre-deployment verification (per fix, before touching anything)

- **Dependencies**: confirmed in CP1 — no migration, no new secret, no new environment variable
  for any of the three fixes. `has_system_admin()`/`users.is_system_admin` (Fix 3's DB
  prerequisite) already live in production since Go-Live Phase 2.
- **CI/CD path**: none exists for Edge Functions (confirmed in CP1) — the only deploy mechanism is
  `supabase functions deploy <name> --project-ref hhdkjfpgaklhrhfoxlhj`, the same command used
  throughout Go-Live Phases 1 and 3.
- **Rollback procedure**: confirmed available for every function before deploying (per-function
  `git show <pre-fix-commit>~1:<path>`, or `supabase functions delete <name>` for the 2
  first-time deploys) — not needed in the end.

## Fix 1 — P2-2 (`calculate-commission`)

- **Pre-deploy state**: version 3, `updated_at` 2026-06-29 (stale, pre-dates commit `2c13f47`).
- **Action**: `supabase functions deploy calculate-commission --project-ref hhdkjfpgaklhrhfoxlhj`.
- **Result**: succeeded, no error. Version bumped **3 → 4**, `updated_at` 2026-07-06T09:40:09Z,
  content hash changed (`ezbr_sha256` differs from pre-deploy).
- **Sanity check** (not the full exploit reproduction — that is CP3's job): a real POST with a
  non-existent `booking_id` and no real user JWT returned `{"error":"unauthenticated"}` / `401` —
  the function is alive, responding correctly, no crash, no timeout.

## Fix 3 — P2-9 (`update-remote-config`, `rollback-remote-config`)

- **Pre-deploy state**: both **absent from production** (confirmed 404 in CP1) — this is a first
  deploy, not a redeploy.
- **Action**: `supabase functions deploy update-remote-config --project-ref hhdkjfpgaklhrhfoxlhj`,
  then the same for `rollback-remote-config`.
- **Result**: both succeeded, no error. Both now appear in `supabase functions list` at **version
  1**, `updated_at` 2026-07-06T09:41:06Z / 09:41:18Z.
- **Sanity check**: real POSTs to both (no real user JWT) returned `{"error":"unauthenticated"}` /
  `401` each — **no longer `404`**. Both functions are live, reachable, and rejecting
  unauthenticated callers correctly (their `getAuthenticatedUser()` check runs before the
  `is_system_admin` check this whole exercise exists to validate — full validation of that gate
  itself is CP3's job).

## Fix 2 — P2-5 (body-size guard, 16 functions total)

3 of the 16 (`calculate-commission`, `update-remote-config`, `rollback-remote-config`) were
already redeployed above as part of Fix 1/Fix 3 — same code, same deploy, not repeated. The
remaining **13** were deployed one at a time, independently, each verified before moving to the
next:

| # | Function | Pre-deploy version | Post-deploy version | Result |
|---|---|---|---|---|
| 1 | `accept-invitation` | v5 | v6 | OK |
| 2 | `check-permissions` | v2 | v3 | OK |
| 3 | `claim-referral` | v3 | v4 | OK |
| 4 | `create-booking` | v7 | v8 | OK |
| 5 | `create-manual-invoice` | v3 | v4 | OK |
| 6 | `create-payment` | v4 | v5 | OK |
| 7 | `create-walkin-booking` | v4 | v5 | OK |
| 8 | `execute-workflow` | v5 | v6 | OK |
| 9 | `mark-no-show` | v4 | v5 | OK |
| 10 | `proxipay-confirm` | v2 | v3 | OK |
| 11 | `proxipay-create-session` | v2 | v3 | OK |
| 12 | `send-notification` | v3 | v4 | OK |
| 13 | `validate-qr` | v3 | v4 | OK |

**Zero failures across all 13.** Every deploy command returned `"message":"Deployed Functions."`
with no error, and every version number incremented by exactly 1, each timestamped
2026-07-06T09:4x — confirmed via a fresh `supabase functions list` re-query after the full batch,
not assumed from the individual deploy outputs alone.

**Sanity check on a representative sample** (4 of the 13, chosen to cover different code paths —
booking creation, QR validation, workflow execution, notification dispatch): all responded
cleanly (`401 unauthenticated` for the two that check auth first, `400 missing_fields`/
`missing_event` for the two that validate body shape first) — no `500`, no timeout, no crash.

## Result — all three fixes redeployed, zero failures, no rollback exercised

| Fix | Functions touched | Deploy outcome |
|---|---|---|
| P2-2 | 1 (`calculate-commission`) | Success |
| P2-9 | 2 (`update-remote-config`, `rollback-remote-config`) | Success (first deploy) |
| P2-5 | 16 total (3 shared with above + 13 more) | Success, all 16 |

**No fix failed. No rollback was executed.** Per the prompt's own rule ("do not attempt the
remaining two fixes in the same run if one fails"), the fact all three succeeded independently
means nothing was skipped or short-circuited — each was verified on its own before the next began.

- `flutter analyze`: 0 issues (no Dart code changed this checkpoint).

## Next

Per the governing prompt: **STOP here.** Checkpoint 3 (Live Validation — the real before/after
exploit reproduction against production) requires Mylord's explicit authorization before starting.
