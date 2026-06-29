# PHASE 2 — Automation Platform — Summary

## Scope
A generic Trigger → Conditions → Actions workflow engine: catalog tables,
a salon-scoped workflow/condition/action model, two Edge Functions
(`execute-workflow`, `run-scheduled-actions`), 4 KYNZA-template workflows
auto-seeded per salon, and a Flutter builder/list/execution-log UI. By far
the largest single sub-phase of this initiative — a new async-execution
subsystem, not just a CRUD table.

## What changed

**Migrations:**
- `20260629140000_automation_engine.sql` — `automation_trigger_types`,
  `automation_action_types` (global catalogs), `automation_workflows`,
  `automation_conditions`, `automation_actions` (salon-scoped, RLS
  adapted to `has_role()` not the brief's `auth.jwt()->'app_metadata'`),
  `automation_execution_logs`, `automation_action_runs` (the
  scheduled/retry queue), `add_loyalty_bonus_stamps()` RPC.
- `20260629140100_automation_default_workflows.sql` — auto-seeds the 4
  templates per salon (trigger on `salons` INSERT + backfill for the 2
  salons that already existed — same pattern as Phase 1.4's
  `salon_settings`, done correctly from the start this time).
- `20260630090000_automation_increment_execution.sql` — atomic
  `execution_count` increment (Supabase JS `.update()` can't express
  `count = count + 1`).
- `20260630090100_automation_scheduled_actions_cron.sql` — pg_cron job,
  every 5 minutes, same pg_net + Vault-secret pattern as the existing
  `kynza-booking-reminders` cron.
- `20260630091000_rename_notif_reminder_column.sql` — unrelated but
  found and fixed in passing: renamed `salon_settings.notif_reminder_
  hours_before_2` to `notif_reminder_hours_before2` to match
  json_serializable's actual codegen output (see Phase 1.4 follow-up
  below).

**Deviations from the brief, found while auditing before writing code:**
- **No `subscriptions`-style gap this time, but a different one:** the
  brief's `automation_action_types` includes `send_whatsapp` as a
  separate action from `send_notification`. The existing
  `send-notification` Edge Function already multi-casts to WhatsApp
  automatically (per-user `notification_preferences.whatsapp_enabled` +
  `whatsapp_opt_in`) — there is no separate WhatsApp-only send path to
  build. Registered `send_whatsapp` in the catalog (matches the brief)
  but its handler is the identical `send_notification` implementation.
- **3 of 8 action types are not implemented**, registered with
  `implemented: false` and a `description` explaining why, rather than
  silently no-op'ing or building something half-correct:
  - `send_email` — R14 explicitly forbids email for an operational
    alert, and no email-sending infrastructure exists in this project.
  - `create_invoice` — `invoices.plan_key` is a foreign key to
    `subscription_plans`; the brief's free-form `{amount, description}`
    params don't map onto that schema.
  - `update_stats` — no concrete target exists yet (`mv_daily_revenue`
    is Phase 3 territory).
  Calling any of these returns `{status: "skipped", error:
  "not_implemented_this_phase"}` rather than failing or burning retries.
- **4 of 8 trigger types are not wired to fire**, marked `wired: false`
  in the catalog with a `description` explaining why — found by
  auditing every booking-status transition and the reviews table before
  writing any code:
  - `booking.completed` / `booking.cancelled` — both happen via direct
    Flutter `.update()` calls (`booking_repository_impl.dart`), not an
    Edge Function. Wiring these would mean converting a core,
    heavily-used staff flow to call an RPC/Edge-Function first — real
    regression risk for a flow nothing asked to be touched. Deferred.
  - `review.submitted` — Flutter inserts directly into `reviews`, no
    Edge Function/RPC exists to hook.
  - `loyalty.card_full` — deliberately **not** wired into `validate-qr`
    (which already detects a full card and sends
    `loyalty_reward_available` directly) to avoid sending the same
    notification twice. The trigger fires correctly from this engine's
    own `stamp_loyalty` action when *that* path fills a card — it's
    just not reachable yet because `booking.completed` (the only seeded
    workflow that calls `stamp_loyalty`) isn't wired either.
  - `subscription.expiring` — no recurring check exists anywhere in this
    codebase (confirmed `check-subscription`, listed as already-existing
    in the original master brief, doesn't exist).
  3 of 8 trigger types **are** wired: `booking.created` (`create-booking`),
  `booking.confirmed` (`leapa-webhook`), `booking.no_show` (`mark-no-show`)
  — all via the established `supabase.functions.invoke()` best-effort,
  catch-silenced pattern already used for `send-notification`.

**Real bugs found while testing against the live Edge Functions (not
hypothetical — each one only surfaced by actually invoking the deployed
functions):**
1. `admin.rpc(...).catch(() => {})` threw `catch is not a function` —
   Supabase JS query/RPC builders are thenable (`.then()`) but don't
   implement `.catch()`; only `.functions.invoke()` returns a real
   Promise. Fixed with try/catch.
2. Conditions that evaluated false left **no trace anywhere** — the
   function returned early before ever inserting an
   `automation_execution_logs` row, even though the schema's `status`
   enum explicitly includes `'skipped'` for this exact case. Fixed: a
   skipped execution now gets logged with `error_message:
   'conditions_not_met'` before returning.
3. **Retries silently didn't happen for the common case.** An action with
   `delay_seconds = 0` that failed on its first (inline) attempt was
   marked `'failed'` permanently — only actions that had already been
   queued with `delay_seconds > 0` ever reached `run-scheduled-actions`'
   retry logic. Since most actions in practice run inline, this meant
   "3 retries" silently applied to almost nothing. Fixed by extracting a
   shared `recordActionRunResult()` (in `_shared/automation_actions.ts`)
   that both `execute-workflow` (inline path) and `run-scheduled-actions`
   (cron path) call — a first failure now reschedules with backoff
   regardless of which path ran it.

## Verification
All of the following were run directly against the deployed functions
and the live remote DB (not simulated), with test data cleaned up
afterward (execution-log rows deleted, `execution_count` reset on the
real templates — workflows themselves were left intact):
- **`booking.confirmed` template fires end-to-end**: invoked
  `execute-workflow` → `send_notification` → real `notification_logs`
  rows created (push + in_app delivered).
- **AND conditions**: `amount > 5000 AND amount < 50000` correctly
  passed for `amount=10000`, correctly skipped for `amount=1000`
  (logged with `status: 'skipped'`).
- **OR conditions**: `amount > 5000 OR amount < 100` correctly passed
  for `amount=50`, correctly skipped for `amount=1000`.
- **Delay queueing**: firing `booking.completed` queued its
  `send_notification` action at `scheduled_at = now + 7200s` exactly;
  back-dating it and invoking `run-scheduled-actions` processed it and
  correctly finalized the execution log.
- **Retry with backoff**: a deterministically-failing action went
  `pending(attempt 1, +2min)` → `pending(attempt 2, +4min)` →
  `failed(attempt 3)`, exactly 3 attempts, execution log finalized to
  `'failed'` only once every action reached a terminal state.
- `flutter analyze` → No issues found.
- `flutter test` → 164/164 passed, 0 regressions.
- `dart format` → applied, no outstanding diffs.

## Remaining known gaps
- 4 of 8 trigger types not wired (see above) — `booking.completed`/
  `booking.cancelled` need a Flutter→RPC conversion that wasn't
  undertaken to avoid risking a core staff flow; `review.submitted`
  needs an equivalent hook; `loyalty.card_full` is deliberately
  unreachable until `booking.completed` is wired.
- 3 of 8 action types not implemented (`send_email`, `create_invoice`,
  `update_stats`) — registered honestly in the catalog rather than
  built half-correct or silently dropped.
- The Flutter builder's condition/action editors are functional but
  basic (plain text fields for `field`/`value`, no autocomplete against
  `available_context`, no per-action-type validation beyond what the
  small param forms enforce).
- No drag-to-reorder for conditions/actions — `order_index` is set from
  insertion order only.