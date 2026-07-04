# KYNZA — Edge Functions Reference

> Extends `docs/API_REFERENCE.md` (which lists functions briefly) and `docs/ARCHITECTURE.md` §5
> (common pattern + short catalog) with a complete per-function reference. Source of truth:
> `supabase/functions/*/index.ts`, verified 2026-07-03, recount confirmed 2026-07-04 (Enterprise
> Certification Pass, CP3): 20 real callable functions as of `update-remote-config`/
> `rollback-remote-config`/`run-scheduled-actions` landing in the Backend Enterprise Completion
> pass. All 20 are documented — no invented functions, no omissions.

## 1. Objectifs

Give a developer everything needed to call, extend, or debug any KYNZA Edge Function without
reading its source: trigger source, input/output shape, auth model, idempotency guarantee,
timeout/retry behavior, and side effects — without re-deriving them from `index.ts` each time.

## 2. Architecture

See `docs/diagrams/edge-function-flow.mermaid` for the generic request flow. Shared helpers live
in `supabase/functions/_shared/`:

| File | Purpose |
|---|---|
| `cors.ts` | CORS headers for browser preflight |
| `supabase_admin.ts` | `getAuthenticatedUser(req)` (JWT validation + profile lookup) and `createServiceRoleClient()` (RLS bypass) |
| `rate_limit.ts` | `checkRateLimit(admin, key, max, windowSeconds)` — backed by RPC `check_rate_limit`, fixed-window, **fails open** on error |
| `hmac.ts` | `buildIdempotencyKey(bookingId)` = `${bookingId}_${windowMinute}` (1-min window) + `verifyLeapaSignature()` (HMAC-SHA256, `timingSafeEqual`) |
| `automation_actions.ts` | Shared `runAction()` / `recordActionRunResult()` used by both `execute-workflow` and `run-scheduled-actions`; retry policy: max 3 attempts, backoff 2/4/8 min |
| `fcm.ts`, `whatsapp.ts` | Push/WhatsApp senders used by `send-notification` |
| `leapa.ts` | Leapa API client wrapper (`initiateLeapaPayment`, etc.) |
| `audit.ts` | `activity_logs` insert helper |

**Two calling conventions, verified across all 20 functions:**
1. **Client-invoked**: Flutter calls `supabase.functions.invoke('<name>', body: {...})`. These functions call `getAuthenticatedUser(req)` first — never trust `role`/`salon_id` from the request body.
2. **Server-invoked**: called only by other Edge Functions with the service-role client (`send-notification`, `execute-workflow`) or by pg_cron (`schedule-reminders`, `run-scheduled-actions`). These have **no JWT check at all** — their trust boundary is that only trusted server-side callers can reach them.

Generic error shape: `{ error: "<code>", message?: string }`. 401 for `unauthenticated`; otherwise a function-specific 4xx, or a generic `500 <fn>_failed`.

## 3. Function Catalog

| Function | Trigger | Auth | Idempotent? | Rate limit |
|---|---|---|---|---|
| `create-booking` | Flutter client | JWT, any authenticated user | Via DB `UNIQUE(practitioner_id, start_time)` → `409 slot_taken` | Yes |
| `create-payment` | Flutter client | JWT + `booking.client_id === user.id` | `idempotency_key` UNIQUE, 1-min window | Yes |
| `leapa-webhook` | Leapa (external HTTP) | **HMAC-SHA256** signature only, no JWT | Explicit `already_processed` short-circuit | 120/60s, global bucket (`leapa-webhook:global`) |
| `mark-no-show` | Flutter client (staff) | JWT + owner/manager/assigned practitioner | **None** — re-callable, no unique guard | Yes |
| `send-notification` | Other Edge Functions only | **None** (trusted server-to-server) | None — every call inserts new logs | None |
| `schedule-reminders` | pg_cron, hourly (`0 * * * *`) | Service-role bearer (cron), no in-function check | Explicit dedupe via `notification_logs` existence check | N/A |
| `accept-invitation` | Flutter client | JWT; blocks `role === owner` | Atomic conditional UPDATE (`invitation_accepted_at IS NULL`) | Yes |
| `create-walkin-booking` | Flutter client (owner/manager) | JWT + `salon_id` match + role | Same `UNIQUE(practitioner_id, start_time)` as create-booking | Yes |
| `validate-qr` | Flutter client (staff/manager/owner) | JWT + role | Atomic conditional UPDATE (`used_at IS NULL AND expires_at > now`) | Yes |
| `claim-referral` | Flutter client (deep link) | JWT; blocks self-referral | Atomic conditional UPDATE + `upsert(onConflict: salon_id,client_id)` | Yes |
| `create-manual-invoice` | Flutter client (owner) | JWT + `role === owner` | **None** — new invoice row every call | Yes |
| `calculate-commission` | Flutter client (post-completion) | JWT, any authenticated | `staff_commissions.booking_id` UNIQUE → `skipped: already_calculated` | Yes |
| `execute-workflow` | Other Edge Functions only | **None** (trusted server-to-server) | None at top level; inner actions use `automation_action_runs` + retry | None |
| `create-backup` | Flutter client (owner/manager) | JWT + role | Cooldown-based: max 1 per 6h per salon (not key-based) | Cooldown |
| `check-permissions` | Flutter client (batch) | JWT; self-or-owner/manager re-enforced server-side | N/A (read-only) | Yes (30/60s) |
| `proxipay-create-session` | Flutter client (staff) | JWT + role + `booking.salon_id` match | **None** — multiple concurrent sessions possible per booking | Yes (30/60s) |
| `proxipay-confirm` | Flutter client (client) | JWT, any authenticated | `status === confirmed` short-circuit + `idempotency_key` UNIQUE | Yes (20/60s) |
| `run-scheduled-actions` | pg_cron, every 5 min (`*/5 * * * *`) | Service-role bearer (cron), no in-function check | Picks `pending` rows, `attempt_count < 3`, shared backoff w/ execute-workflow | N/A |
| `update-remote-config` | Flutter client (owner, Backend Enterprise Completion Phase 4) | JWT + `role === owner` (interim — see note below) | Per-key JSON-schema-style validation before any write; never partial | Yes (60/60s) |
| `rollback-remote-config` | Flutter client (owner, Backend Enterprise Completion Phase 4) | JWT + `role === owner` (interim — see note below) | Restores to a prior `remote_config_versions` row, always append-only | Yes (30/60s) |

**Extra function not in the original 18 named in prior specs: `run-scheduled-actions`** — included above.

**Access-control note for the 2 Phase 4 functions**: gated to `role === 'owner'` as an interim
measure, because no `SYSTEM_ADMIN` scope exists yet (`docs/backend-completion/
PHASE_1_FINAL_AUDIT.md` §3, item 9 — assigned to Phase 2/CP3 of the Backend Enterprise
Completion pass). Remote config values are platform-wide, not salon-scoped, so any owner being
able to change them is broader than ideal — flagged honestly in the function source itself, to
be tightened once `SYSTEM_ADMIN` lands.

## 4. `check-subscription` — confirmed does not exist

No Edge Function, RPC, or cron job named or behaving as `check-subscription` exists anywhere in
this codebase. This is a known, previously-documented gap:

- `supabase/migrations/20260629140000_automation_engine.sql` seeds the `subscription.expiring`
  automation trigger type explicitly marked `wired: FALSE` — *"no recurring check exists
  anywhere in this codebase (no cron, no check-subscription)."*
- There is no `subscriptions` table. Plan state lives on plain columns: `salons.plan`,
  `salons.plan_status`, `salons.plan_started_at`.

**What actually governs plan/subscription state today:**
1. **Upgrade**: Flutter → `create-manual-invoice` Edge Function → pending `invoices` row (bank
   transfer reference, placeholder per known tech debt).
2. **Mark paid**: Flutter calls RPC `mark_invoice_paid` **directly** (`billing_repository_impl.dart`)
   — same "RPC called directly from Flutter" pattern as `evaluate_feature_flag`. Flips
   `salons.plan`/`plan_status` atomically inside Postgres.
3. **Downgrade**: Flutter does a **direct `.update()`** on `salons` — no Edge Function involved.
4. **Freemium limits** (distinct from plan *expiry*): enforced inline inside `create-booking` and
   `create-walkin-booking` (`plan === 'free' && monthly_bookings_count >= 20` → `403
   freemium_limit_reached`). Counter reset monthly by a separate pg_cron job
   (`reset-monthly-bookings-count`, `20260623262000_monthly_bookings_counter.sql`).
5. **No cron-driven expiry check exists** — a paid plan that lapses is never automatically
   flipped back to `free`. This is the actual gap `subscription.expiring` was seeded for.

This is tracked as a tech-debt item in `docs/PRODUCTION_CHECKLIST.md` (Part 14 will append it).

## 5. Per-Function Detail

### create-booking
- **Input**: `salonId, serviceId, practitionerId, startTime (ISO), notes?`
- **Output**: `{ booking }` (full row)
- **Errors**: `400 missing_fields`, `400 slot_in_past`, `403 freemium_limit_reached`, `404 service_not_found`, `409 slot_unavailable`, `409 slot_taken`, `429 rate_limit_exceeded`
- **Side effects**: `activity_logs` (`booking_created`); best-effort `send-notification` (`booking_created`) + `execute-workflow` (`booking.created`); best-effort `owner_journey_progress.step_first_booking_done` update.
- **UI state on failure**: `error` (KynzaErrorState + retry), except `slot_taken`/`slot_unavailable` which should re-render the slot picker (not a generic error).

### create-payment
- **Input**: `bookingId, method, phone?`
- **Output**: `{ idempotencyKey, status }` or `{ idempotencyKey, alreadyPending: true }`
- **Errors**: `400 missing_fields`, `403 forbidden`, `404 booking_not_found`, `409 booking_not_payable`, `429`, `502 leapa_initiation_failed`
- **Side effects**: inserts `transactions` row only; settlement handled by `leapa-webhook`.

### leapa-webhook
- **Trigger**: external, Leapa → `POST /leapa-webhook`. **No JWT** — HMAC-SHA256 over raw body (`x-leapa-signature` header) is the sole trust boundary. Rule: always read `rawBody` before `JSON.parse`.
- **Input**: `idempotency_key, status, leapa_reference, leapa_transaction_id, method`
- **Output**: `{ status: "ok" }` / `{ message: "already_processed" }`
- **Side effects**: on `completed` — updates `bookings.status/payment_status`, `activity_logs` (`payment_completed`), `send-notification` (`booking_confirmed`, awaited) + best-effort `execute-workflow` (`booking.confirmed`).

### mark-no-show
- **Input**: `bookingId`
- **Output**: `{ status: "no_show", reliabilityScore }`
- **Errors**: `403 forbidden`, `404 booking_not_found`, `409 grace_period_not_elapsed` (≥15 min after start), `429`
- **Side effects**: `bookings` update, `users.reliability_score` −1 (floor 0), `activity_logs` only at the 3rd-strike threshold. **Not idempotent** — re-calling re-decrements the score; treat as a client-side one-shot action (disable the button after first tap).

### send-notification
- **Trigger**: internal only (other Edge Functions)
- **Input**: `{ event, bookingId?, userId?, salonId?, relatedBookingId?, data? }`
- **Output**: always `200` — `{ status: "sent" | "skipped" }` (best-effort dispatcher, never throws)
- **Side effects**: reads `notification_templates`/`notification_preferences`/`users.fcm_token|whatsapp_phone`; sends FCM + WhatsApp (each channel's failure caught independently); inserts one `notification_logs` row per channel attempted plus always one `in_app` row.

### schedule-reminders
- **Trigger**: pg_cron hourly (`0 * * * *`, `20260624062000_schedule_reminders_cron.sql`)
- **Output**: `{ status: "ok", sent }`
- **Idempotency**: skips a `(booking, event_type)` pair already present in `notification_logs`.
- **Side effects**: calls `send-notification` for `booking_reminder_24h` / `booking_reminder_2h`.

### accept-invitation
- **Input**: `invitation_token`
- **Output**: `{ success: true, salon_id, role }`
- **Errors**: `400 already_owner`, `400 invalid_invitation` (checked pre- and atomically at update time)
- **Side effects**: `staff_profiles`/`users` update, `activity_logs` (`staff_invitation_accepted`), best-effort `send-notification` (`staff_joined`) to inviter.

### create-walkin-booking
- **Input**: `salonId, serviceId, practitionerId, startTime, guestFirstName, guestPhone, notes?`
- **Output**: `{ booking }` (`status: confirmed`, `payment_method: cash`)
- **Auth**: `caller.salon_id === salonId` and `role ∈ {owner, manager}`
- **Side effects**: may call `auth.admin.createUser()` (service-role only) for a guest identity; `activity_logs` (`booking_created`, `walkIn: true`). **Asymmetric with `create-booking`**: no `send-notification`/`execute-workflow` call here.

### validate-qr
- **Input**: `token` (a `loyalty_qr_tokens.id`)
- **Output**: `{ success: true, action: "stamp"|"redeemed", clientName, stampsCount, stampsRequired }`
- **Side effects**: RPC `add_loyalty_stamp` or `redeem_loyalty_reward`; `activity_logs`; best-effort `send-notification` (`loyalty_reward_available`) when a card completes.

### claim-referral
- **Input**: `referral_token`
- **Output**: `{ success: true, stampGranted, salonName }`
- **Errors**: `400 self_referral`, `400 invalid_referral`
- **Side effects**: `loyalty_cards` upsert (`onConflict: salon_id,client_id`), RPC `add_loyalty_stamp` for both parties, `referrals.status → rewarded`, `activity_logs`, best-effort notification.

### create-manual-invoice
- **Input**: `plan_key`
- **Output**: `{ success: true, invoice }`
- **Auth**: `role === owner`
- **Side effects**: `invoices` insert (triggers `entity_versions` via DB `AFTER INSERT` trigger, not in-function code), `activity_logs` (`invoice_created`).

### calculate-commission
- **Input**: `booking_id`
- **Output**: `{ success: true, amountBif }` or `{ success: true, skipped: reason }`
- **Errors**: `400 booking_not_completed`
- **Side effects**: `staff_commissions` insert (UNIQUE on `booking_id`), `activity_logs`.

### execute-workflow
- **Trigger**: internal only — called by `create-booking`, `leapa-webhook`, `mark-no-show`, `_shared/automation_actions.ts`'s `stampLoyalty`
- **Input**: `{ trigger_type, salon_id, context }`
- **Output**: always `200` — `{ status: "processed", results: [...] }`
- **Side effects**: `automation_execution_logs` + `automation_action_runs` insert; `runAction()` can write `activity_logs` and/or call `send-notification`; RPC `increment_workflow_execution` (best-effort). Delayed actions (`delay_seconds > 0`) are queued for `run-scheduled-actions`; inline actions retry via shared `recordActionRunResult()` (max 3, backoff 2/4/8 min).

### create-backup
- **Input**: none (salon derived from JWT)
- **Output**: `{ job_id, status: "completed", storage_path, file_size_bytes, records_exported }`
- **Rate limit**: cooldown, max 1 per 6h per salon (checked against recent `backup_jobs`)
- **Side effects**: `backup_jobs` lifecycle (`running` → `completed`/`failed`); exports salons/services/staff/clients/bookings (90d)/reviews/invoices (90d) as JSON to Storage bucket `kynza-backups`.

### check-permissions
- **Input**: `{ permissions: [{ feature, action, resource?, userId? }] }` (max 50)
- **Output**: `{ results: { "<userId>:<feature>.<action>[.<resource>]": boolean } }`
- **Security note**: re-enforces the self-or-owner/manager guard server-side since the admin client bypasses `check_permission()`'s own guard — a staff/client caller cannot probe another user's permissions.
- **Note**: single-flag checks bypass this function entirely and call RPC `check_permission()` directly from `lib/core/permissions/permission_service.dart` — this function is the batch path only.

### proxipay-create-session
- **Input**: `bookingId`
- **Output**: `{ sessionId, amountBif, expiresAt }` — **no secret exposed**; amount always re-read from `booking` server-side, never trusted from the request.
- **Auth**: `role ∈ {owner, manager, staff}` + `booking.salon_id === user.salon_id`
- **Errors**: `409 booking_not_collectible`
- **Gap**: no unique constraint prevents multiple concurrent sessions for the same booking.

### proxipay-confirm
- **Input**: `sessionId, method, phone`
- **Output**: `{ sessionId, idempotencyKey, status }` — **`phone` is never persisted** on `proxipay_sessions`, only forwarded to Leapa.
- **Errors**: `410 session_expired`, `409 booking_not_collectible`
- **Side effects**: `transactions` insert, `proxipay_sessions` update (`confirmed`). Settlement/notification arrives later via `leapa-webhook`.

**`proxipay_sessions` RLS** (`20260702120000_proxipay_sessions.sql`): RLS enabled with only two
`SELECT` policies (`salon staff`, and `pending AND not expired` — the client-facing read during
active pairing). **No `INSERT`/`UPDATE`/`DELETE` policy exists for `authenticated`** — under
Postgres RLS semantics, omission denies the command by default, functionally equivalent to
`WITH CHECK (FALSE)`. Both mutating paths use `createServiceRoleClient()`, bypassing RLS
entirely, consistent with the intent.

### run-scheduled-actions
- **Trigger**: pg_cron every 5 min (`*/5 * * * *`, `20260630090100_automation_scheduled_actions_cron.sql`)
- **Output**: `{ status: "processed", count }`
- **Idempotency**: picks `automation_action_runs` where `status = pending AND scheduled_at <= now() AND attempt_count < 3`, batch 50; shares backoff policy with `execute-workflow`.
- **Side effects**: updates `automation_action_runs`; can write `activity_logs`/call `send-notification`; finalizes `automation_execution_logs` once all runs for an execution are no longer pending.

### update-remote-config
- **Input**: `key, value, change_reason?`
- **Output**: `{ success: true, key, value, version }`
- **Errors**: `400 missing_fields`, `400 malformed_value` (type or category-refinement mismatch), `403 forbidden`, `404 unknown_key`, `429 rate_limit_exceeded`
- **Validation**: looks up the entry's `value_type`, rejects any submitted value whose runtime type doesn't match; additionally rejects negative numbers for `prices`/`quotas`/`rate_limits` categories and non-`#RRGGBB` strings for `theming` — a malformed value never reaches `remote_config_entries`, let alone a client.
- **Side effects**: `remote_config_versions` (new row, `version_number` incremented), `remote_config_audit` (`action: 'updated'`).

### rollback-remote-config
- **Input**: `key, version_number`
- **Output**: `{ success: true, key, value, version }` (the newly created version number, not the target one — rollback is append-only, never destructive)
- **Errors**: `400 missing_fields`, `403 forbidden`, `404 unknown_key`, `404 unknown_version`, `429 rate_limit_exceeded`
- **Side effects**: `remote_config_entries.value_json` restored to the target version's exact value; `remote_config_versions` (new row copying that value), `remote_config_audit` (`action: 'rolled_back'`).

## 6. Sécurité

- Every client-invoked function validates the caller via `getAuthenticatedUser()` — role/salon_id
  are never trusted from the request body (see `docs/SECURITY.md` for the full RLS pattern).
- `leapa-webhook` uses HMAC-SHA256 over the **raw** body as its sole trust boundary — never
  re-serialize before verifying.
- `send-notification` and `execute-workflow` have **no JWT check at all** by design — they are
  reachable only via `supabase.functions.invoke` from other server-side code using the
  service-role client. They must never be exposed as directly client-callable in future changes.
- ProxiPay functions confirmed to never expose or persist secrets/phone numbers beyond what's
  strictly needed (verified line-by-line above).
- `check-permissions` re-enforces its own authorization guard server-side rather than trusting
  the underlying RPC's guard, because it runs with the admin client.

## 7. Performance

- Timeout budget: not explicitly configured per-function in code (Supabase Edge Functions default
  timeout applies — no custom `AbortController`/timeout logic found in any of the 20 functions).
  This is a gap worth flagging, not a documented guarantee — treat as **unspecified**, not
  "reasonable."
- Retry policy: only `execute-workflow`/`run-scheduled-actions` have explicit retry (max 3,
  backoff 2/4/8 min, shared via `_shared/automation_actions.ts`). All other functions are
  one-shot; client-side retry (e.g. re-tapping a button) relies on the idempotency guarantees
  documented per-function above — for functions with **no** idempotency guarantee
  (`mark-no-show`, `create-manual-invoice`, `proxipay-create-session`), the client must disable
  the triggering control after first tap rather than rely on server-side dedup.
- Rate limiting: `checkRateLimit()` fails open on error (availability over strict enforcement) —
  a Postgres outage on the rate-limit table does not block the underlying action.

## 8. Stratégie de tests

No dedicated Edge Function test suite exists yet in this repo (Deno tests were out of scope for
the 244 Flutter tests). Recommended coverage (not yet implemented — tracked as tech debt):
unit tests per function using Deno's test runner + a mocked service-role client; integration
tests against a Supabase branch/preview DB for the idempotency and RLS-omission behaviors
documented above (especially `proxipay_sessions`' no-INSERT-policy behavior, which is easy to
regress silently).

## 9. Documentation associée

- `docs/ARCHITECTURE.md` §5 — condensed catalog, cross-link only, not duplicated here.
- `docs/SECURITY.md` — JWT/RLS pattern, Vault secrets list (Part 7/12 will reconcile the missing
  ProxiPay secret).
- `docs/ARCHITECTURE_GLOBAL.md` + `docs/diagrams/communication-diagram.mermaid` — end-to-end
  booking creation sequence including this function.
- `docs/diagrams/edge-function-flow.mermaid` — generic request flow.

## 10. Critères d'acceptation

- [x] All 20 real functions documented — `check-subscription` explicitly confirmed absent, not invented.
- [x] `run-scheduled-actions` (not in the original named list) included.
- [x] Every function's auth model stated as what the code actually checks, not assumed.
- [x] ProxiPay secret-exposure and RLS-omission claims verified against actual file contents, not asserted.
- [ ] Concrete timeout numbers — **not achievable**: no function sets an explicit timeout; documented as a gap (§7) rather than fabricated.

## 11. Livrables

- `docs/EDGE_FUNCTIONS_REFERENCE.md` (this file)
- `docs/diagrams/edge-function-flow.mermaid`
