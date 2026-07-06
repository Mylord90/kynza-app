# Checkpoint 1 — Pre-Deployment

**Date**: 2026-07-06. **Scope**: rediscover, from the source documents (not from memory or
assumption), exactly which three fixes are still officially open at the end of Production Go-Live,
and pin down precisely where each lives, which commit introduced it, what it affects, and exactly
why production isn't aligned. No redeploy happens in this checkpoint.

## Rediscovery method

Read, in order, exactly as instructed:
1. `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` — Master Inventory.
2. `docs/go-live/FINAL_PRODUCTION_CERTIFICATION.md` — the most recent phase report.
3. Git history for the exact commits that introduced each fix.
4. Live production state via `supabase functions list` and direct HTTP calls — not assumed from
   any report.

**Result — unambiguous, cross-confirmed in both source documents**: `FINAL_PRODUCTION_
CERTIFICATION.md` names them explicitly three times (§1, §3, §8, §9, closing checklist) as
**P2-2, P2-5, P2-9** — no other candidate is named as "still open" anywhere in either document.
The Master Inventory's own rows for these three IDs (lines 61/64/68) independently corroborate
the same three, with the same "Corrigé-non-déployé" status and the same reasoning. No ambiguity
found — proceeding with these three, not guessed, cross-confirmed.

---

## Fix 1 — P2-2: `calculate-commission` cross-tenant commission leak

**Exactly where it lives**: `supabase/functions/calculate-commission/index.ts`, lines 44-50 — an
ownership check (`if (caller.salon_id !== booking.salon_id) return jsonResponse({ error:
"forbidden" }, 403);`) inserted right after the booking is fetched, before any commission data is
computed or returned.

**Commit that introduced it**: `2c13f47` — `security(cp11): draft fixes for CP2/CP4 findings,
none deployed` (2026-07-04 14:24:52). The commit's own message states explicitly: "Nothing
applied or deployed... the function code changes are ordinary source edits, neither reaching
production without a separate, explicit db push / functions deploy this pass does not perform."

**What's affected**: 1 Edge Function (`calculate-commission`). No migration, no RLS policy, no
new table — reads `bookings`/`staff_profiles`, writes `staff_commissions`, all pre-existing
tables. `caller.salon_id` is sourced from `getAuthenticatedUser()` (`_shared/supabase_admin.ts`),
which selects it from the `users` table — a column `protect_user_columns` already makes immutable
via the client API, so it can't be spoofed by the caller.

**Which environment has it**:
- `kynza-dr-scratch`: **has it** — deployed version 7, `updated_at` 2026-07-05T21:06:22.945Z
  (after the fix commit).
- Production (`hhdkjfpgaklhrhfoxlhj`): **does not have it** — deployed version 3, `updated_at`
  2026-06-29T11:27:41.974Z, five days *before* the fix commit even existed.

**Precisely why production isn't aligned**: confirmed via direct timestamp comparison (deployed
version pre-dates the fix commit by 5 days) that this is genuinely "the redeploy step was never
executed," not a partial/failed deploy or a different divergence. Corroborated by this project's
CI/CD: `.github/workflows/ci.yml`'s only `deploy` job is an unwired Android-bundle placeholder
(`"No deploy target is wired yet."`) — every Edge Function deploy in this project's entire
history has been a manual `supabase functions deploy` via CLI, and no such command was ever run
for this fix.

---

## Fix 2 — P2-5: no body-size limit on 16 Edge Functions

**Exactly where it lives**: `supabase/functions/_shared/cors.ts`, lines 22-45 — the
`checkBodySize()` function (rejects any request with `Content-Length` over 100KB with a `413`,
*before* `req.json()` ever buffers/parses the body). Wired into the top of the `Deno.serve`
handler in 16 files (confirmed by direct `grep -l "checkBodySize"` across every function
directory — exactly 16 matches, no more, no fewer):

```
accept-invitation, calculate-commission, check-permissions, claim-referral, create-booking,
create-manual-invoice, create-payment, create-walkin-booking, execute-workflow, mark-no-show,
proxipay-confirm, proxipay-create-session, rollback-remote-config, send-notification,
update-remote-config, validate-qr
```

**Commit that introduced it**: `ab5cadb` — `feat(enterprise-final-100): CP2 -- security closure:
body-size DoS guard, system-admin grant/revoke audit trail, PermissionGuard wired live,
rate-limiter silence fixed` (2026-07-05 18:17:24), confirmed via `git show ab5cadb --stat`
listing exactly these 16 files plus `_shared/cors.ts`/`_shared/rate_limit.ts`.

**What's affected**: 16 Edge Functions, no migration, no RLS, no new table — a pure code-level
guard, self-contained (reads only `Content-Length`, no new secret/env var/dependency).

**Which environment has it — precise, not assumed**:
- `kynza-dr-scratch`: only **7 of the 16** are actually deployed there at all (`create-booking`,
  `calculate-commission`, `create-payment`, `proxipay-create-session`, `proxipay-confirm`,
  `update-remote-config`, `rollback-remote-config`), each at a version dated after the fix commit
  — genuinely live-tested for those 7. **The other 9** (`accept-invitation`, `check-permissions`,
  `claim-referral`, `create-manual-invoice`, `create-walkin-booking`, `execute-workflow`,
  `mark-no-show`, `send-notification`, `validate-qr`) have **never been deployed to dr-scratch
  either** — the code fix is identical and present in git for all 16 (same 2-line pattern per
  file), but 9 of them have never actually been exercised live anywhere, on any project. This is
  a more precise statement than prior reports' "live-tested on dr-scratch" framing, which was true
  for the mechanism (`checkBodySize` itself, proven via the 7 that were deployed) but not for
  every one of the 16 individual call sites.
- Production: **14 of the 16 exist but all pre-date the fix commit** (stale, same pattern as
  `calculate-commission` above); **2 (`update-remote-config`, `rollback-remote-config`) do not
  exist in production at all** — see Fix 3 below, same two functions.

**Precisely why production isn't aligned**: same root cause as Fix 1 — no `functions deploy` was
ever run for any of the 16 after `ab5cadb`. Confirmed via `supabase functions list` timestamps for
the 14 that exist, and via a direct live HTTP 404 for the 2 that don't (shared evidence with Fix 3).

---

## Fix 3 — P2-9: Remote Config admin gate uses `role==='owner'` instead of `has_system_admin()`

**Exactly where it lives**: `supabase/functions/update-remote-config/index.ts` line 76
(`if (!caller.is_system_admin) return jsonResponse({ error: "forbidden" }, 403);`) and
`supabase/functions/rollback-remote-config/index.ts` line 23 (identical check).

**Commit that introduced it**: `d9c7613` — `feat(master-plan-execution): CP1-CP5 -- security
re-verification, deployment-ready migration batch, cold-start cache, backup automation, Android
release closure` (2026-07-05 17:41:45) — confirmed via `git show d9c7613` diff on both files,
changing `if (caller.role !== "owner")` to `if (!caller.is_system_admin)`. This commit **predates**
`ab5cadb` (the `checkBodySize` commit) by about 36 minutes, so both functions' current source
carries both fixes.

**What's affected**: 2 Edge Functions. **Dependency**: `has_system_admin()` (Postgres function)
and `users.is_system_admin` (column) — both created by migration `20260704120000_observability_
system_admin.sql`. **This dependency is already live in production**, confirmed directly this
session: `select proname from pg_proc where proname='has_system_admin'` returns a row (applied
during Go-Live Phase 2, migration #8 of that batch). No remaining DB-side precondition.

**Which environment has it**:
- `kynza-dr-scratch`: **has it** — both functions deployed at version 6, `updated_at`
  2026-07-05T14:21:38-44Z (after the fix commit, before `checkBodySize` was even added — this
  version already reflects the `is_system_admin` gate).
- Production: **more severe than "stale" — these two functions do not exist in production at
  all.** Confirmed two independent ways: (1) `supabase functions list --project-ref
  hhdkjfpgaklhrhfoxlhj` returns 20 functions, and neither `update-remote-config` nor
  `rollback-remote-config` appears anywhere in that list; (2) a direct, real HTTP `POST` to both
  endpoints returns `404 {"code":"NOT_FOUND","message":"Requested function was not found"}` — not
  a `403`/`500`, an actual missing-function response. This means the underlying vulnerability
  (`role==='owner'` gate) is **not currently reachable/exploitable in production today** — there
  is no deployed function running the old code — but the entire admin-facing Remote Config write
  path (both update and rollback) is **absent from production**, which is itself the reason this
  is still tracked as open: closing it requires a **first deploy**, not a redeploy.

**Precisely why production isn't aligned**: genuinely "never deployed," not "deployed then
regressed" — confirmed by the complete absence from `functions list` and the `404` response, a
stronger and more precise finding than the Master Inventory row's existing "neither function was
among those Phases 1-3 redeployed" phrasing (accurate, but doesn't capture that they were never
deployed even once before this go-live program began touching Remote Config's Edge Function side).

---

## Rollback feasibility, confirmed before proceeding

- **Fix 1 (`calculate-commission`)**: rollback = redeploy the pre-`2c13f47` version of the file
  (`git show 2c13f47~1:supabase/functions/calculate-commission/index.ts`), or `supabase functions
  delete calculate-commission` if a full removal is ever needed (it is not — this function is
  actively called by the app's booking-completion flow).
- **Fix 2 (16 functions)**: rollback per function = redeploy the pre-`ab5cadb` version
  (`git show ab5cadb~1:supabase/functions/<name>/index.ts`) — every file's diff is a clean,
  isolated 2-line addition (import + one guard call), trivially revertible per file independently.
- **Fix 3 (`update-remote-config`/`rollback-remote-config`)**: rollback = `supabase functions
  delete update-remote-config` / `... rollback-remote-config` — since these don't exist in
  production today, "rollback" is simply removing what this checkpoint adds, not reverting to an
  older version.

## CI/CD path confirmed

No automated deploy pipeline exists for Edge Functions in this project — `.github/workflows/
ci.yml`'s only `deploy` job is an unwired Android-bundle placeholder. Every Edge Function
deployment in this project's history, including all of Go-Live Phases 1/3, has been a manual
`supabase functions deploy <name> --project-ref <ref>` via the Supabase CLI. Checkpoint 2 will use
the same, already-proven mechanism.

## Result

All three fixes located with file/line precision, commit-traced, and their exact production gap
confirmed by direct live inspection (not assumption) — one is a stale-code gap (Fix 1, and 14 of
Fix 2's 16 functions), and two are complete first-deploy gaps (the 2 functions shared between
Fix 2 and Fix 3). No ambiguity encountered. No redeploy performed in this checkpoint.

## Next

Per the governing prompt: **STOP here.** Checkpoint 2 (Safe Redeployment) requires Mylord's
explicit authorization before starting.
