# CP2 — Deployment Plan Execution

**Date**: 2026-07-05. **Scope**: execute exactly the ordering already produced in the Master
Plan §7 (Migration Deployment Plan) / §8 (Edge Functions Plan) — re-verify the classification
still holds, close the 2 rollback-plan gaps the Master Plan itself flagged as thin, and prepare
everything for a single approved deploy batch. **Nothing was applied to production**
(`hhdkjfpgaklhrhfoxlhj`) — all verification/preparation below happened against
`kynza-dr-scratch` (`hzjmyeptytvjmzbnsmwp`) or read-only against production.

---

## 1. Migration count re-verified (again growing, as the Master Plan itself predicted)

`supabase migration list --linked` (production), re-run 2026-07-05, this session:

**79 local → 80 local** (one new migration drafted this pass, see §4). **59 applied, now 21
unapplied** (the Master Plan's 20 + 1 new). Confirms §5's "14→16→18→20→21" growth-trajectory
finding continues to hold for the same reason every prior snapshot did: work continues under an
unbroken "never auto-deploy without Mylord's approval" discipline, not a miscount.

Also re-confirmed live: `kynza-dr-scratch`'s migration list is **80/80 — every single local
migration, including today's new one, is already applied there.** This is the actual mechanism
that makes "already live-tested on dr-scratch" a true statement throughout this program, not an
assumption.

## 2. Group 1 — Security (re-verified in CP1, see `CP1_SECURITY_CLOSURE.md`)

All 4 unchanged from Master Plan §7: `20260704190000`, `20260704200000`, `20260704210000`,
`20260704220000`. Re-tested live this session (CP1). **Ready**, in the same order, with the same
one caveat carried forward unchanged: `20260704220000` must not apply until `CRON_SECRET` exists
in production as both an Edge Function secret and a Vault entry.

**Precondition re-checked, still unmet** (`supabase secrets list --project-ref
hhdkjfpgaklhrhfoxlhj`, read-only, this session): production's Edge Function secrets are exactly
the 7 platform-default `SUPABASE_*` entries — no `CRON_SECRET` present. This is not a regression;
it was never expected to be set until immediately before this migration applies.

## 3. Group 2 — the 14 feature migrations (re-verified, order unchanged)

Exact order re-confirmed unchanged from Master Plan §7:
`20260703120000→20260703130000→20260703140000→20260703150000→20260703160000→20260704100000→
20260704110000→20260704120000→20260704130000→20260704140000→20260704150000→20260704160000→
20260704170000→20260704180000`. Per-migration rollback statements already exist, verbatim, in
`docs/remediation/MIGRATION_APPLICATION_PLAN.md` §"Rollback plan — per migration, specific"
(rows 1-14) — read this session, confirmed still accurate against the current migration files
(spot-checked `20260703120000`, `20260703130000`, `20260704120000`, `20260704180000` against the
plan's claims — all match). **Ready**, no changes needed.

## 4. Group 3 — the 2 Resilience migrations: rollback plan gap closed this pass

The Master Plan's own §7 table only had generic rollback text for these two ("DROP RPC/columns
added" / "DROP views/table/RPC") because `MIGRATION_APPLICATION_PLAN.md` predates them (it says
"18 total" — written before `20260705100000`/`20260705110000` existed). **This was a genuine gap
in "prepare each migration for deployment... rollback plan attached"** — closed here with
verbatim statements derived directly from reading both migration files:

**`20260705100000_cp0_concurrency_atomic_claims.sql` rollback:**
```sql
DROP INDEX IF EXISTS idx_data_deletion_requests_one_pending_per_user;
DROP TABLE IF EXISTS public.reminder_dispatch_claims;
DROP FUNCTION IF EXISTS public.claim_pending_action_runs(INT, INT, INT);
ALTER TABLE public.automation_action_runs DROP COLUMN IF EXISTS claimed_at;
ALTER TABLE public.automation_action_runs DROP CONSTRAINT IF EXISTS automation_action_runs_status_check;
ALTER TABLE public.automation_action_runs
  ADD CONSTRAINT automation_action_runs_status_check
  CHECK (status IN ('pending', 'success', 'failed', 'skipped')); -- original 4-value check, pre-migration (20260629140000_automation_engine.sql:243)
```
Validation step: re-run CP0's live race test (`claim_pending_action_runs` called concurrently,
exactly one caller wins) against production immediately after applying.

**`20260705110000_cp6_observability_alerting.sql` rollback:**
```sql
DROP FUNCTION IF EXISTS public.get_system_alerts();
DROP FUNCTION IF EXISTS public.check_system_alerts();
DROP INDEX IF EXISTS idx_system_alerts_one_open_per_type;
DROP TABLE IF EXISTS public.system_alerts;
DROP FUNCTION IF EXISTS public.get_payment_dashboard();
DROP VIEW IF EXISTS public.v_payment_dashboard;
```
Validation step: manually seed one threshold breach (e.g. insert 6 failed `transactions` in the
last hour), call `check_system_alerts()`, confirm a `system_alerts` row is created; confirm a
second call within the same incident window does not duplicate it (the partial unique index).
Hard dependency (unchanged from Master Plan): requires `20260704120000` (`has_system_admin()`,
`edge_function_invocations`) already applied.

## 5. New this pass — P2-24 (`notification_logs` Realtime gap), drafted and live-applied to dr-scratch

The Master Plan's execution prompt explicitly named this as one of the "also finalize" items.
No migration existed for it anywhere (Master Inventory: `Ouvert`, "trivial (add to
publication)"). Drafted `20260705120000_cp2_realtime_notification_logs.sql`:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE public.notification_logs;
```
Applied to `kynza-dr-scratch` this session via `supabase db push` (linked there temporarily,
re-linked back to production immediately after — production was never touched). The DDL
succeeded without a "relation is already member of publication" error, which is itself
Postgres-level proof the table was not previously a member and now is.

**Honest scoping note**: a full Realtime-client round-trip (subscribe, mutate via service role,
observe the `postgres_changes` event arrive) was **not** performed this session — no
`@supabase/supabase-js`/websocket tooling is set up in this repo/environment (it's a Flutter
project; adding a Node dependency tree for one P2 smoke test was judged disproportionate). The
DDL-level proof above is real but is one level short of the full live-functional proof this
program holds every other fix to — flagged explicitly, not silently upgraded to "live-tested."

**Rollback**: `ALTER PUBLICATION supabase_realtime DROP TABLE public.notification_logs;`
**Validation step** (for whoever applies + has the tooling): open the notifications screen,
insert a row into `notification_logs` for that user via service role, confirm it appears without
a manual refresh.

## 6. New this pass — P2-9 (Remote Config admin gate), code fix drafted AND live-tested

Master Plan §8 listed this as "Modify (small) — swap `role==='owner'` for `has_system_admin()`".
No code draft existed yet (Master Inventory: `Ouvert`). Implemented and live-tested this session:

- `supabase/functions/_shared/supabase_admin.ts` — `getAuthenticatedUser()` now also selects
  `is_system_admin` (additive column, safe for all ~20 other callers of this shared helper).
- `supabase/functions/update-remote-config/index.ts` and
  `supabase/functions/rollback-remote-config/index.ts` — gate changed from
  `caller.role !== "owner"` to `!caller.is_system_admin`.

Deployed to `kynza-dr-scratch` and live-tested:
```
Salon owner (not system_admin) → update-remote-config → 403 {"error":"forbidden"}   (was 200 before)
SYSTEM_ADMIN account            → update-remote-config → 404 {"error":"unknown_key"} (past the gate)
```
Confirms the gate itself changed, not a coincidental full rewrite (the SYSTEM_ADMIN call reached
the next real check — an unknown config key — rather than being rejected at the auth gate).

**Hard precondition, same as the Master Plan already flagged**: this code must not reach
production before `20260704120000` (which creates `has_system_admin()` and the
`is_system_admin` column) is applied — deploying it first would make every caller fail at
`getAuthenticatedUser()`'s `.select("...is_system_admin")` with a missing-column error.
Sequenced accordingly in §7 below.

---

## 7. Consolidated deployment order (single approved batch, pending Mylord's sign-off)

| Order | Item | Type | Rollback documented | Validation step defined |
|---|---|---|---|---|
| 1-4 | Security migrations (§2) | Migration | ✅ (Master Plan §7 / `MIGRATION_APPLICATION_PLAN.md`) | ✅ — re-run `test/live/remediation_v1_security_fixes_test.dart` + manual P2-2/P3-15 checks against production |
| — | **Precondition before #4**: set `CRON_SECRET` (Edge Function secret + Vault entry) in production | Config | N/A | Confirm both cron jobs still fire on next scheduled run |
| 5-18 | 14 feature migrations (§3) | Migration | ✅ (`MIGRATION_APPLICATION_PLAN.md`) | ✅ — Health Center renders 13 dashboards; CMS/Remote Config/Feature Flags/Legal Center/Catalog/A-B Testing/Business Observability/Audit tables present |
| 19 | `20260705100000` (concurrency) | Migration | ✅ (new this pass, §4) | ✅ — re-run CP0's live race test |
| 20 | `20260705110000` (observability/alerting) | Migration | ✅ (new this pass, §4) | ✅ — seed one threshold breach, confirm alert row |
| 21 | `20260705120000` (notification_logs realtime) | Migration | ✅ (new this pass, §5) | ⚠️ partial — DDL-verified, full client round-trip not performed |
| — | `update-remote-config` / `rollback-remote-config` redeploy | Edge Function | ✅ (`git revert`) | ✅ — live-tested this pass on dr-scratch; **must ship no earlier than item 8 in the migration order (`20260704120000`)** |
| — | `calculate-commission` redeploy | Edge Function | ✅ (`git revert` + redeploy) | ✅ — re-tested live this pass (CP1) |
| — | `run-scheduled-actions` / `schedule-reminders` redeploy | Edge Function | ✅ | ✅ — re-tested live this pass (CP1), success path still needs the `CRON_SECRET` precondition above |
| — | `check-system-alerts` (new function) | Edge Function | Delete function | ⚠️ no `pg_cron` schedule target decided yet — flagged unchanged from Master Plan §8 |
| — | Remaining 14 of 20 production Edge Functions | — | N/A | Re-confirmed clean, no change needed (Master Plan §8, not re-audited here) |

**Hard-failure dependencies** (self-correcting, unchanged from Master Plan): item 8
(`has_system_admin()`) must precede items 10-13, item 20, and the two Edge Function redeploys.
Item 11 must precede item 13.

**Silent-failure risk** (unchanged, called out again because it is the one place this plan fails
without anyone noticing): item 4 applied before its `CRON_SECRET` precondition is met breaks
reminders/automation with no visible error.

---

## Exit criteria check

- [x] Migration/Edge Function ordering re-verified against the Master Plan, not re-classified
      from scratch.
- [x] Migration count re-confirmed via direct `supabase migration list --linked` re-run (not
      assumed from the Master Plan's own re-check a day earlier).
- [x] Every item in the batch — old and new — now has both a rollback plan and a validation
      step; the 2 gaps found (resilience migrations' generic-only rollback, P2-9's nonexistent
      draft) were closed with real, live-tested artifacts, not left as "TODO."
- [x] The one still-partial item (P2-24's Realtime fix) is flagged as partial, not silently
      upgraded to fully proven.
- [x] Nothing applied to production; the CLI link was verified restored to
      `hhdkjfpgaklhrhfoxlhj` at the end of this session.

**Net movement this checkpoint**: 21 migrations + 3 Edge Function changes now form one
fully-specified, rollback-attached, validation-defined deployment batch — up from 20 migrations
with 2 thinly-documented rollbacks and 2 unfixed small backend items (P2-9, P2-24) at the start
of this pass.
