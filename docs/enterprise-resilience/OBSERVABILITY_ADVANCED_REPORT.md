# CP6 — Observability Avancée

**Enterprise Resilience & Reliability Certification (Final) — 2026-07-05**

## 1. Re-verification: the prior verdict still holds

The Final Enterprise Validation pass's direct verdict was **"KYNZA is NOT production-observable
today"** — `edge_function_invocations` doesn't exist in production because its migration
(`20260704120000_observability_system_admin.sql`) is one of 16 never deployed. Re-checked live
today (read-only `supabase migration list` against `hhdkjfpgaklhrhfoxlhj`): **still true, unchanged**
— that migration, and every migration through this pass's own `20260705110000`, still shows no
applied timestamp against production. This checkpoint does not re-argue that finding — it drafts
what closes it, per the brief.

## 2. What already existed in draft (not built new by this checkpoint)

`20260704120000_observability_system_admin.sql` already contains, drafted and verified-on-
dr-scratch by the prior pass: `edge_function_invocations` table, and dashboards for Supabase schema
health, storage, notifications, automation queue depth, Edge Function stats, crash reporting, and
security/rate-limiting — each gated behind a `has_system_admin()`-checked `SECURITY DEFINER` RPC.
Solid monitoring surface. What it does **not** have, confirmed by reading the full file: any
payment-specific dashboard, and — the headline gap — **no alerting mechanism of any kind**. A
dashboard nobody is paged by is not the same as being observable in an incident.

## 3. What this checkpoint drafted

New migration `20260705110000_cp6_observability_alerting.sql` (depends on `20260704120000`
already being applied first):

- **`v_payment_dashboard` + `get_payment_dashboard()`** — hourly payment success/failure/expired/
  reversed counts by method, from the existing `transactions` table (no new write path needed).
- **`system_alerts` table** — `alert_type` (`edge_function_error_rate` / `sync_queue_depth` /
  `payment_failure_rate`), `severity`, `message`, `metric_value`, `threshold_value`,
  `triggered_at`/`resolved_at`. A partial unique index enforces **at most one open alert per
  type at a time** — the same claim-discipline CP0 established, applied here so a 5-minute
  re-check doesn't spam a new row every cycle while an incident is still ongoing.
- **`check_system_alerts()`** — a `SECURITY DEFINER` function evaluating all three thresholds CP6
  named at minimum:
  - Edge Function error rate **> 10%** over the last 15 minutes (minimum 10 invocations sampled,
    to avoid a false alarm from e.g. 1-error-out-of-2-calls on a quiet function).
  - Sync queue depth, measured as **staleness** (oldest still-pending/processing
    `automation_action_runs` row **> 30 minutes** old) rather than raw row count — a deliberate
    choice: 5 rows stuck for an hour matters more than 50 rows that are all seconds old for a
    low-volume system like this one.
  - Payment failure rate **> 20%** over the last hour (minimum 5 transactions sampled).
- **`check-system-alerts`** (draft Edge Function) — calls the RPC above and, for each newly-fired
  alert, sends a WhatsApp message to a configured ops contact via the *same* `_shared/whatsapp.ts`
  helper `send-notification` already uses (no second integration introduced). A failed WhatsApp
  send never loses the alert — the `system_alerts` row is already committed by the RPC regardless
  of delivery outcome. Same `CRON_SECRET` gate as `run-scheduled-actions`/`schedule-reminders`.
  A `pg_cron` schedule for this function (every 5 minutes, mirroring `run-scheduled-actions`) is a
  documented follow-up, not created here — it would need to target production to have any effect,
  out of scope for a draft-only checkpoint.

**Not applied to production** per Rule 8 — applied only to `kynza-dr-scratch` to run the test below.

## 4. Live test: does the drafted design actually catch a critical incident?

Simulated three concurrent incidents on `kynza-dr-scratch` in one pass:

1. **Edge Function failures**: seeded 12 `edge_function_invocations` rows for a fake function,
   4 of them `error` (33% error rate).
2. **Stuck sync queue**: seeded one `automation_action_runs` row with `scheduled_at` 45 minutes in
   the past, still `pending`.
3. **Payment failures**: seeded 6 `transactions` rows, 3 `failed` (50% failure rate).

Called `check_system_alerts()` directly (the same call the draft Edge Function makes):

```
Alert types fired: ['edge_function_error_rate', 'payment_failure_rate', 'sync_queue_depth']
PASS: all 3 injected incidents were caught.

"Edge Function error rate 33.3% over last 15 min (8 errors / 24 invocations)"
"2 automation_action_runs rows pending/processing; oldest is 47 minutes old"
"Payment failure rate 50.0% over last hour (3 failed / 6 total)"
```

(The 8/24 and "2 rows" counts reflect a small amount of leftover seed data from an earlier failed
test iteration in the same session, cleaned up before the final verification pass below — the
detection logic itself is what's being proven, not the exact row counts.)

Called it again immediately afterward, with the incidents still present:

```
New alerts on second call: 0
PASS: dedup suppressed a duplicate alert.
```

Confirms the one-open-alert-per-type constraint works exactly as designed — a real incident that
persists across multiple 5-minute cron ticks produces exactly one alert (and one WhatsApp message,
were it deployed with `OPS_ALERT_WHATSAPP_NUMBER` configured), not one per tick.

All simulated rows and alerts were deleted immediately after verification; `kynza-dr-scratch` left
in its prior state (confirmed via a follow-up query showing zero leftover rows).

## 5. Honest scope boundary

- The WhatsApp dispatch side of `check-system-alerts` was **not** live-tested end-to-end (that
  would require a real `WHATSAPP_TOKEN`/`OPS_ALERT_WHATSAPP_NUMBER` and an actual outbound message
  to a real phone — out of scope to fire from an automated test in this session). What was proven
  is the detection/dedup logic (`check_system_alerts()` itself); the notification dispatch path
  reuses `sendWhatsappText`, which is already exercised elsewhere in the codebase (`send-
  notification`), not new/unproven code.
- No `pg_cron` schedule was created for `check-system-alerts` — doing so meaningfully requires a
  production target, out of scope for a draft-only checkpoint.
- Thresholds (10% error rate, 30-minute staleness, 20% payment failure rate) are this checkpoint's
  own reasoned defaults, not values pulled from an existing incident-response policy (none exists
  in the repo to reconcile against) — worth Mylord's review before deployment, flagged explicitly
  rather than presented as authoritative.

## 6. Exit criteria

- [x] Re-verified the prior verdict live rather than re-asking the question: production is still
  not observable (migration `20260704120000` and everything after it remain undeployed).
- [x] Drafted the missing monitoring piece CP6 named (`v_payment_dashboard`) and the missing
  alerting mechanism (thresholds for all 3 named metrics: error rate, sync queue depth, payment
  failure rate).
- [x] Live-simulated a critical incident and confirmed the drafted design catches it — not
  asserted, run and observed.
- [x] Confirmed the dedup/one-open-alert-per-type mechanism prevents alert spam on repeated
  cron ticks during a sustained incident.
- [x] No production writes; `kynza-dr-scratch` left clean.
