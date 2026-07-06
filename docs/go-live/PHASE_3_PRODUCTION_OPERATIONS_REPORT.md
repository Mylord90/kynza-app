# Phase 3 — Production Operations Report

**Date**: 2026-07-06. **Scope**: turn on the operational backbone that Phase 2 wired at the DB
layer but couldn't fully activate on its own — backups, monitoring, alerting, and the cron jobs
that drive them. Executed under the KYNZA — Production Go-Live Execution prompt's Phase 3,
authorized by Mylord's "continue" after Phase 2's report.

## Before deploying — the exact gap this phase closes

Phase 2's own report flagged two honest, non-silent gaps rather than overstating completeness:
1. `run-scheduled-actions`/`schedule-reminders` had the DB-side cron-secret precondition met, but
   the *deployed* function code didn't check the header yet.
2. `20260705130000` registered the `kynza-platform-backup` cron job, but `create-platform-backup`
   itself had never been deployed — the job would 404 on its first run.

This phase closes both, plus activates the alerting mechanism (`check-system-alerts`) that had no
`pg_cron` schedule at all yet (P1-12's own row said so explicitly).

## Actions taken, each with real evidence

### 1. Edge Function deploys

Four functions deployed/redeployed to production (`supabase functions deploy <name> --project-ref
hhdkjfpgaklhrhfoxlhj`), each a first-time deploy or a redeploy of already-committed, already
dr-scratch-tested code — no new code written this phase:

| Function | Action | Confirmed live behavior |
|---|---|---|
| `create-platform-backup` | First deploy | Real invocation succeeded (see §2) |
| `check-system-alerts` | First deploy | Real invocation succeeded (see §4) |
| `run-scheduled-actions` | Redeploy (adds cron-secret check + atomic-claim usage) | Anon-only call now `403 {"error":"forbidden"}`; correct-secret call `200` |
| `schedule-reminders` | Redeploy (adds cron-secret check + atomic-claim usage) | Anon-only call now `403 {"error":"forbidden"}` |

**P2-3 is now genuinely closed end-to-end** — both the DB precondition (Phase 2) and the function
enforcement (this phase) are live, confirmed by a real unauthenticated request against production
itself, not inferred.

### 2. Backup — deployed, run for real, and restore-verified

- `create-platform-backup` deployed, then triggered for real with the production `CRON_SECRET`:
  ```
  {"job_id":"6f1274f2-0204-4f88-9a82-b5607c182792","status":"completed",
   "storage_prefix":"platform/2026-07-06T06-26-01-795Z",
   "tables_exported":79,"rows_exported":258,"total_bytes":94879}
  ```
- `platform_backup_jobs` row confirmed matching (`status: completed`, same counts).
- **Artifact confirmed genuinely retrievable**: downloaded `_manifest.json` and `salons.json`
  directly from the `kynza-backups` storage bucket via the service-role key — real JSON, real
  content, byte counts matching the manifest exactly (2 rows, 1554 bytes).
- **Restore verification performed against `kynza-dr-scratch`, never production**: linked the CLI
  to dr-scratch, created a throwaway table (`kynza_restore_verification`), inserted the exact 2
  `salons` rows downloaded from the *production* backup artifact, confirmed every field matched
  byte-for-byte, then dropped the table — no permanent footprint left on dr-scratch. This proves
  the backup artifact is actually usable, not merely present, exactly as the phase's own
  instruction requires ("never restore into production itself").

**RPO is now bounded at ≤6h in production** (the registered cron cadence), not unbounded as it
was before this phase.

### 3. Cron job for alerting — registered

No `pg_cron` schedule existed for `check_system_alerts()` before this phase (P1-12's own row said
so). Added via a new migration, applied the same way as every other migration in this program
(reviewed, then applied directly, then `migration repair`'d into history):

`supabase/migrations/20260706150000_go_live_phase3_check_system_alerts_cron.sql` — registers
`kynza-check-system-alerts` on `*/5 * * * *`, same `X-Cron-Secret`/Vault pattern as every other
cron-driven function in this project. Confirmed live: `active=true`, `schedule='*/5 * * * *'`.

### 4. Alerting — all 3 categories triggered for real, confirmed received

Each threshold was exercised with controlled, clearly-marked test data inserted directly into
production (not simulated on dr-scratch), then `check_system_alerts()` was called, then every
piece of test data and every resulting alert row was deleted immediately after — production is
back to its real, pre-test state.

| Category | Test condition created | Result |
|---|---|---|
| `edge_function_error_rate` | 10 `edge_function_invocations` rows (2 success, 8 error) tagged `kynza-go-live-phase3-test` | Alert recorded: `"Edge Function error rate 80.0% over last 15 min (8 errors / 10 invocations)"`, severity `critical` |
| `sync_queue_depth` | 1 `automation_action_runs` row, `status='pending'`, `scheduled_at` 40 minutes in the past | Alert recorded: `"1 automation_action_runs rows pending/processing; oldest is 40 minutes old"`, severity `warning` |
| `payment_failure_rate` | 5 `transactions` rows (1 completed, 4 failed), tagged `idempotency_key='go-live-phase3-test-*'` | Alert recorded: `"Payment failure rate 80.0% over last hour (4 failed / 5 total)"`, severity `critical` |

**"Received" confirmed** via a direct read of `system_alerts` immediately after triggering — all 3
rows present with the exact expected `alert_type`/`severity`/`message`. (`get_system_alerts()`
itself correctly rejected the same read when attempted through the non-authenticated management
API path — `403 forbidden` — which is the RPC's own admin-only gate working exactly as designed,
not a bug; the direct table read was used instead purely for this verification.)

**WhatsApp dispatch itself was not exercised**: `WHATSAPP_TOKEN`/`WHATSAPP_PHONE_NUMBER_ID` are not
set in production (confirmed via `supabase secrets list`) — these are real external credentials
(Leapa/WhatsApp Business API), already tracked as an External Go-Live Dependency, not something
this phase can or should generate. `check-system-alerts`' own dispatch loop is best-effort by
design: a missing/failed WhatsApp send never blocks the alert from being recorded, which is
exactly what was proven above — the alerting *mechanism* (detection + recording) is fully live;
only the *notification channel* awaits an external credential.

**Cleanup confirmed complete**: `edge_function_invocations`, `transactions`, and
`automation_action_runs`/`automation_execution_logs` all re-checked at 0 test rows; `system_alerts`
re-checked at 0 rows (both the trigger data and the resulting alert rows were removed) — production
is not left with any stale test artifact.

### 5. AtomicClaimService protection — confirmed genuinely exercised, not just present

The phase's own instruction requires confirming this is "exercised," not merely deployed. A direct
functional test only (no real notification/side effect risk, since every real `automation_actions`
row in production is `send_notification`/`stamp_loyalty` — invoking the full pipeline would risk a
real dispatch to a real client):

1. Inserted one real test `automation_execution_logs` + `automation_action_runs` row
   (`status='pending'`), referencing real existing `salon_id`/`workflow_id`/`action_id`.
2. Fired **two truly-parallel HTTP `POST` requests** (via backgrounded shell jobs, both completing
   in ~1.6–1.7 seconds — genuinely overlapping in wall time, not simulated) directly at
   `claim_pending_action_runs()` via PostgREST.
3. **Result**: exactly one call received the row (`status` now `processing`, `claimed_at` set); the
   other call's response was `[]` — an empty result, meaning it found nothing left to claim. This
   is `FOR UPDATE SKIP LOCKED` correctly preventing a double-claim under genuine concurrent load in
   production itself.
4. Test data deleted immediately after (`automation_execution_logs` cascade-deletes its
   `automation_action_runs` row) — 0 rows remain.

Also confirmed one real, ordinary execution cycle of both cron-driven functions completes cleanly
in production with nothing pending: `run-scheduled-actions` → `{"status":"processed","count":0}`;
`check-system-alerts` → `{"status":"checked","newAlerts":0,"dispatched":0}` — both `200`, both
correct given production currently has no real pending work.

## After — final validation

- **`flutter analyze`**: 0 issues (no Dart code changed this phase — Edge Function/SQL only).
- **Production `pg_cron` jobs, final state**: `kynza-booking-reminders`, `kynza-run-scheduled-actions`,
  `kynza-platform-backup`, `kynza-check-system-alerts` (new), plus the 3 pre-existing jobs
  (`kynza-refresh-audit-stats`, `refresh-mv-daily-revenue`, `release-expired-bookings`,
  `reset-monthly-bookings-count`) — all `active=true`.
- **Migration count**: 87 local, 87 applied, 0 unapplied (the one new migration this phase,
  `20260706150000`, applied and validated the same way as every migration in Phase 2).
- **No production data left over from testing**: re-confirmed 0 rows across every table touched
  for verification purposes.

## Result

Every operational gap Phase 2 explicitly flagged is now closed, with real evidence — not just
"deployed" but *exercised*: a real backup ran and was restore-verified, all 3 alert categories
fired and were recorded, and the atomic-claim mechanism was proven exclusive under an actual
concurrent race in production. P1-3, P1-9 (server), P1-12, and P2-3 are now `Fermé (preuve)` in
the Master Inventory.

## Next

Per the governing prompt: **STOP here.** Phase 4 (Final Production Certification) requires
Mylord's explicit authorization before starting, same as every prior phase — the prompt's "no
STOP required" language applies only *after* Phase 4 completes, not before it begins.
