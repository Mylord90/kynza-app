# Phase 2 — Security P0/P1/P2 Remediation: Tested Fixes, Deployed to Nothing

> Per the remediation prompt's Rule: a finding is not closed by being documented again. Every fix
> below was applied to `kynza-dr-scratch` (never production), exploited before, re-exploited after,
> and reverted/cleaned up. **None of these fixes are applied anywhere in production.** All 5 are
> `DRAFTED, AWAITING APPROVAL` per Rule 8.
>
> Four of the five fixes already existed as drafts from the prior Certification v2 pass (CP2/CP4/
> CP6/CP11/Gate 0) — this phase's job was to actually *apply and exploit-test* them for the first
> time (no prior pass had done this; they were all still "drafted, never applied/deployed anywhere,
> including staging"). Doing so surfaced **2 real bugs in the prior drafts** that would have shipped
> broken fixes had they been applied as-is — both found and corrected here, with before/after
> evidence for the correction itself, not just the original vulnerability.

## Summary table

| # | Finding | Matrix ID | Before (exploit) | After (blocked) | Bug found in the draft? |
|---|---|---|---|---|---|
| 1 | `staff_profiles.invitation_token` public exposure | P0-1 | ✅ live-exploited | ✅ confirmed blocked | **Yes** — `security_invoker=true` silently broke the replacement view for its own intended audience |
| 2 | `staff_profiles.salon_id` mass-assignment | P1-1 | ✅ live-exploited | ✅ confirmed blocked | No |
| 3 | `create_default_document_templates` unauthenticated write | P2-1 | ✅ live-exploited | ✅ confirmed blocked | No |
| 4 | `get_staff_week_rank` loose anon grant | P3-15 | ✅ confirmed loose | ✅ confirmed tightened | **Yes** — `REVOKE ... FROM anon` was a no-op; real grant came from `PUBLIC` |
| 5a | `calculate-commission` cross-tenant disclosure | P2-2 | ✅ live-exploited | ✅ confirmed blocked, legit path still works | No |
| 5b | `run-scheduled-actions`/`schedule-reminders` cron-secret bypass | P2-3 | ✅ live-exploited (both functions) | ✅ confirmed blocked, secret path works end-to-end | **Yes** — drafted `pg_cron` job names didn't match the real ones |

---

## 1. `staff_profiles.invitation_token` public exposure (P0-1)

**Before** (anon key, zero auth, against `kynza-dr-scratch`):
```
GET /rest/v1/staff_profiles?select=id,invitation_token&invitation_accepted_at=is.null
→ HTTP 200, content-range 0-999/3003 — 3,003 pending invitation tokens returned, no auth required
```

**Fix applied** (`supabase/migrations/20260704190000_cp6_fix_staff_invitation_token_exposure.sql`):
drops the public policy, replaces it with a column-limited view `v_staff_directory_public`
(excludes `invitation_token`/`phone`/`invited_by`), invalidates all unclaimed tokens.

**Real bug found while testing**: the drafted view used `WITH (security_invoker = true)`. Applied
as-is, the view returned `[]` (empty) to `anon` — because `security_invoker=true` makes the view
apply the *querying role's* RLS on the underlying `staff_profiles` table, and `anon` had just lost
its only policy there. Confirmed live:
```
-- anon querying the view, invoker=true (buggy draft):
GET /rest/v1/v_staff_directory_public?select=*&salon_id=eq.<salon> → HTTP 200, []
-- authenticated staff querying the same view: only ever their OWN row, never a salon-mate's
```
This would have silently emptied `practitioner_selection_screen.dart`'s practitioner picker for
every client, permanently, the moment this migration reached production — a full feature outage
masquerading as a security fix. **Corrected**: removed `security_invoker` (views default to
definer-style — the correct, deliberate tool here, since the view's whole purpose is controlled
access beyond base-table RLS, made safe by its own column exclusion and `WHERE` clause, not by
inheriting RLS).

**After** (re-applied with the fix, re-tested):
```
GET /rest/v1/staff_profiles?select=id,invitation_token → HTTP 200, []           (base table: blocked)
GET /rest/v1/v_staff_directory_public?select=*&salon_id=eq.<salon>
  → HTTP 200, [{"id":"...","salon_id":"...","role":"staff","display_name":"Staff A",
               "avatar_url":null,"bio":null,"specialties":null,"is_active":true,
               "invitation_accepted_at":null}]                                  (view: real data, safe columns)
GET /rest/v1/v_staff_directory_public?select=id,invitation_token
  → HTTP 400 {"code":"42703", "message":"column v_staff_directory_public.invitation_token does not exist"}
```
The feature works again for its real audience, and `invitation_token` isn't even a requestable
column on the replacement view — not just permission-denied, structurally absent.

**Cleanup**: none needed — the fix was left applied on `kynza-dr-scratch` (an intended improvement
to the reusable sandbox, not test pollution).

---

## 2. `staff_profiles.salon_id` mass-assignment (P1-1)

**Before**: signed in as the real QA Salon A staff account (`kynza.qa.a.staff@example.com`, via a
temporary password set through the Admin API, reset to a fresh random value afterward):
```
PATCH /rest/v1/staff_profiles?id=eq.fa29c69f-... {"salon_id":"a49c40c3-...(QA Salon B)"}
Authorization: Bearer <Salon A staff's own JWT>
→ HTTP 200 — salon_id actually changed to Salon B
```
Reverted immediately via service-role PATCH back to the original `salon_id`.

**Fix applied** (`supabase/migrations/20260704200000_cp2_fix_staff_profiles_salon_id_mass_assignment.sql`,
applied unmodified — no bug found here):

**After** (exact same PATCH, same JWT):
```
→ HTTP 403 {"code":"42501","message":"new row violates row-level security policy for table \"staff_profiles\""}
```

---

## 3. `create_default_document_templates` unauthenticated write (P2-1)

**Before** (anon key only, no user JWT at all):
```
POST /rest/v1/rpc/create_default_document_templates {"p_salon_id":"<QA Salon A>"}
→ HTTP 204 — succeeded, fully unauthenticated
```

**Fix applied** (bundled in `supabase/migrations/20260704210000_cp11_hardening_batch.sql`,
unmodified — no bug found in this half of the migration): adds
`has_role(auth.uid(), 'owner'|'manager', p_salon_id)` check.

**After** (exact same call):
```
→ HTTP 400 {"code":"P0001","message":"forbidden"}
```

---

## 4. `get_staff_week_rank` loose anon grant (P3-15)

**Before**: `has_function_privilege('anon', 'get_staff_week_rank(uuid)', 'execute')` → `true`.

**Real bug found**: the draft's `REVOKE EXECUTE ON FUNCTION public.get_staff_week_rank(uuid) FROM
anon;` was applied, then re-checked — still `true`. Root cause: `pg_proc.proacl` showed a bare
`=X/postgres` entry, PostgreSQL's implicit grant to the `PUBLIC` pseudo-role (present by default
unless revoked at creation); every role, including `anon`, inherits `PUBLIC`'s privileges
regardless of a role-specific `REVOKE`. The original draft revoked a grant that never existed
(anon-specific) while leaving the real access path (`PUBLIC`) untouched.

**Corrected**: `REVOKE EXECUTE ON FUNCTION public.get_staff_week_rank(uuid) FROM PUBLIC;`

**After**:
```
has_function_privilege('anon', ...)          → false
has_function_privilege('authenticated', ...) → true   (legitimate callers unaffected)
```

---

## 5a. `calculate-commission` cross-tenant financial disclosure (P2-2)

Reconstructed the pre-fix version from git history (`git show 2c13f47~1:...`, confirmed the diff
against the current file is exactly the ownership check, nothing else) and deployed it to
`kynza-dr-scratch` temporarily to get a real "before."

Set up a real completed booking for QA Salon B (`amount_bif: 15000`, staff commission rate 20%
temporarily).

**Before** (Salon A staff JWT, reading Salon B's booking):
```
POST /functions/v1/calculate-commission {"booking_id":"<Salon B booking>"}
Authorization: Bearer <Salon A staff JWT>
→ HTTP 200 {"success":true,"amountBif":3000}   -- learned Salon B's exact commission, zero relationship
```
Cleaned up the resulting `staff_commissions`/`activity_logs` rows immediately (the vulnerable
version's insert is real, not simulated).

**Fix applied** (code patch already committed to `supabase/functions/calculate-commission/
index.ts` — no bug found, deployed unmodified): rejects unless `caller.salon_id === booking.salon_id`.

**After** (exact same call):
```
→ HTTP 403 {"error":"forbidden"}
```

**Sanity check — legitimate same-salon call still works** (own booking, own salon, 10% rate):
```
→ HTTP 200 {"success":true,"amountBif":2000}
```

**Cleanup**: deleted both synthetic test bookings, their `staff_commissions`/`activity_logs` rows,
and reset both staff members' `commission_rate` back to `0`.

---

## 5b. `run-scheduled-actions` / `schedule-reminders` — cron-secret bypass (P2-3)

Reconstructed pre-fix versions from git history for both functions (diff confirmed: exactly the
cron-secret check, nothing else) and deployed each temporarily.

**Before** (both functions, just the public anon key — no special secret):
```
POST /functions/v1/run-scheduled-actions  (Authorization: Bearer <anon key>) → HTTP 200 {"status":"processed","count":0}
POST /functions/v1/schedule-reminders     (Authorization: Bearer <anon key>) → HTTP 200 {"status":"ok","sent":0}
```
Confirms the "cron-only trust" was never real — the public anon key shipped in the Flutter app is
sufficient.

**Real bug found**: the companion migration
(`supabase/migrations/20260704220000_cp11_cron_secret.sql`) assumed `pg_cron` job names
`schedule-reminders-hourly`/`run-scheduled-actions-5min`. Queried the real `cron.job` table on
both `kynza-dr-scratch` **and production** (read-only): the real names on both projects are
`kynza-booking-reminders` and `kynza-run-scheduled-actions`. Applying the original draft would have
left the old, unsecured jobs running unmodified (name mismatch → `WHERE EXISTS` no-ops) alongside
new, differently-named ones — doubling reminder/action-runner frequency, exactly the risk the
draft's own comment warned about without having verified it. **Corrected** the job names in the
migration.

**Fix applied** (code patches already committed to both functions — no bug found in the code
itself, deployed unmodified) + corrected migration, applied to `kynza-dr-scratch` with both
preconditions actually satisfied (`CRON_SECRET` function secret set via `supabase secrets set`;
matching Vault secret created via `vault.create_secret`):

**After**:
```
run-scheduled-actions, no secret header → HTTP 403 {"error":"forbidden"}
run-scheduled-actions, correct X-Cron-Secret → HTTP 200 {"status":"processed","count":0}
schedule-reminders, no secret header → HTTP 403 {"error":"forbidden"}
schedule-reminders, correct X-Cron-Secret → HTTP 200 {"status":"ok","sent":0}
```

**Full end-to-end proof, not just the Edge Function in isolation**: read the actual `cron.job`
command text after applying the migration and executed it verbatim (exactly what `pg_cron` would
run on schedule) — both jobs resolved their Vault-sourced URL/service-role-key/cron-secret
correctly and got a real `200` back:
```
kynza-run-scheduled-actions → net._http_response: status_code 200, {"status":"processed","count":0}
kynza-booking-reminders     → net._http_response: status_code 200, {"status":"ok","sent":0}
```
(This required adding `project_url`/`service_role_key` Vault secrets to `kynza-dr-scratch` — they
already exist in production, confirmed read-only, where these same 2 cron jobs are running
successfully every 5/60 minutes; `kynza-dr-scratch` had simply never had the one-time manual Vault
bootstrap step described in `supabase/migrations/20260624062000_schedule_reminders_cron.sql`'s own
header comment. Adding them is a genuine improvement to the reusable sandbox, not test pollution —
left in place.)

---

## What was NOT deployed anywhere

- No migration was applied to production. All 4 SQL migrations above were applied only to
  `kynza-dr-scratch`.
- All 3 Edge Function deploys (`calculate-commission`, `run-scheduled-actions`,
  `schedule-reminders`) were to `kynza-dr-scratch` only (`--project-ref hzjmyeptytvjmzbnsmwp`),
  never to the linked production project.
- The `CRON_SECRET` function secret and Vault entries were set on `kynza-dr-scratch` only.

## Corrections made to the drafted migrations (now part of the draft, still unapplied to production)

- `supabase/migrations/20260704190000_cp6_fix_staff_invitation_token_exposure.sql` — removed
  `security_invoker = true` from the view definition (see finding 1).
- `supabase/migrations/20260704210000_cp11_hardening_batch.sql` — changed `REVOKE ... FROM anon`
  to `REVOKE ... FROM PUBLIC` for `get_staff_week_rank` (see finding 4).
- `supabase/migrations/20260704220000_cp11_cron_secret.sql` — corrected both `pg_cron` job names
  (see finding 5b).

## Test artifacts cleaned up on `kynza-dr-scratch`

- 2 synthetic test bookings + their `staff_commissions`/`activity_logs` rows (created and deleted
  this phase for the `calculate-commission` test).
- 2 staff members' `commission_rate` reset to `0` (their pre-test state).
- QA Salon A staff account's temporary password reset to a fresh random value (never recorded),
  then — **correction made during Phase 4** after discovering the existing `test/live/` suite's
  `LiveTestEnv.signIn()` expects a fixed shared QA password (`Kynza-QA-Test-2026!` by default) —
  reset again to that documented shared value, verified by a real sign-in call, so this pass
  doesn't silently break the pre-existing live test suite's ability to authenticate as that
  fixture.
- The reverted `salon_id` PATCH (back to its original value).

## Left in place on `kynza-dr-scratch` (intentional improvements, not pollution)

- `v_staff_directory_public` view + dropped public policy (the actual fix).
- Tightened `staff_own_profile_update` policy (the actual fix).
- Tightened `create_default_document_templates` + revoked `get_staff_week_rank` PUBLIC grant (the
  actual fixes).
- Deployed patched `calculate-commission`/`run-scheduled-actions`/`schedule-reminders`.
- `CRON_SECRET` function secret + Vault entry, and (newly added) `project_url`/`service_role_key`
  Vault entries.
- Updated `kynza-booking-reminders`/`kynza-run-scheduled-actions` `pg_cron` job definitions (now
  send the cron secret).

## Status of all 5 findings after this phase

All 5 remain **fix drafted, awaiting Mylord's explicit approval** to apply to production — Phase 2
proves the fixes work and don't regress, it does not change their production deployment status.
See `MASTER_ISSUES_MATRIX.md` (P0-1, P1-1, P2-1, P2-2, P2-3, P3-15) for updated evidence links.
