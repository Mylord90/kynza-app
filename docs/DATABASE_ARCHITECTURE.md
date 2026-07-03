# KYNZA — Database Architecture

> Full reference for all 55 tables in the live Supabase schema, extracted directly from the 59
> migration files actually applied to the remote project out of 62 total in
> `supabase/migrations/` (verified 2026-07-03 via `supabase migration list --linked`, cross-checked
> again independently in Phase 2 of the Enterprise Hardening pass — see
> `docs/audit/SCHEMA_RECONCILIATION_REPORT.md`). Extends `docs/ARCHITECTURE.md` §4 (RLS/
> soft-delete/auto-seed patterns) and `docs/API_REFERENCE.md` (RPC catalog) — those patterns are
> not repeated here, only cited.

## 1. Objectifs

A complete, per-table map of the schema — columns, constraints, RLS policies, indexes, triggers
— so a developer can add a feature touching any table without reading 58 migration files first.

## 2. Architecture

See [`docs/diagrams/erd.mermaid`](diagrams/erd.mermaid) for the full entity-relationship diagram,
grouped by domain. **Note on the discrepancy with prior counts**: this codebase currently has
**55 tables**, not the ~47 referenced in earlier project documentation — the schema grew through
the RBAC, audit, entity-versioning, automation, data-platform, and evolution-platform phases
(all shipped 2026-06-29 through 2026-07-02, after the last table count was taken). All 55 are
listed below.

Multi-tenancy pattern (`salon_id` server-derived, RLS via `has_role()`) and the soft-delete
convention (`deleted_at IS NULL` filtering, no `DELETE`) are documented in `docs/ARCHITECTURE.md`
§4.1–4.3 and `docs/SECURITY.md` — this document assumes that pattern and calls out **every
exception to it** explicitly (§5).

## 3. Table Reference by Domain

Legend: **SD** = has `deleted_at`; **RLS** = policy summary; **Idx** = notable indexes beyond the
implicit PK.

### 3.1 Identity / RBAC

| Table | Migration | SD | RLS | Idx / notes |
|---|---|---|---|---|
| `users` | `20260622182007_foundation.sql` +5 later ALTERs | Yes | Self SELECT/UPDATE only; column-level immutability (`salon_id`/`role`/`email_verified`/`reliability_score`) via `protect_user_columns()` trigger, with a narrow one-time onboarding exception | `idx_users_salon`, `idx_users_email` (UNIQUE partial), `idx_users_role_salon`. **Gap**: `idx_users_salon` doesn't filter `deleted_at` |
| `permission_definitions` | `20260629100000_rbac_enterprise.sql` | No (global catalog) | Read-all for `authenticated`; writes are migration/service_role only | `UNIQUE(feature,action,resource)`, 22 seeded rows |
| `permission_groups` | same | Yes | Owner-only (`FOR ALL`) | `idx_permission_groups_salon` (salon_id+deleted_at). **Bug**: `updated_at` column has no trigger |
| `permission_group_permissions` | same | No (hard-delete via cascade) | Owner-only via join | Invalidates permission cache on change |
| `user_permission_groups` | same | Yes | Owner-only | **Bug**: no `updated_at` trigger (table has no `updated_at` column though, so N/A — verified) |
| `user_permission_overrides` | same | Yes | Owner-only | Cache-invalidation trigger on change |
| `user_effective_permissions_cache` | same | No (ephemeral, hard-deleted by invalidation) | Self or owner SELECT; writes only via `check_permission()` | 15-min TTL (`expires_at`), non-partial composite index |

### 3.2 Salon Core

| Table | Migration | SD | RLS | Idx / notes |
|---|---|---|---|---|
| `salons` | `20260622182007_foundation.sql` + `salon_full_schema` + FTS | Yes | Public SELECT (`is_online=true`); member SELECT; owner INSERT; owner/manager UPDATE; no DELETE policy | GIN trigram + `search_vector`. **Gap**: `owner_id` is not a declared FK and has no index despite being used in RLS checks |
| `salon_media` | `20260623200000_salon_full_schema.sql` | Yes | Owner/manager manage; public SELECT | `idx_salon_media_salon(salon_id, display_order)` |
| `salon_settings` | `20260629130000_salon_settings.sql` | **No** | Owner/manager only | 1:1 via `UNIQUE(salon_id)`. **Bug**: `updated_at` column has no trigger. **Tech debt**: only 1:1 core table without `deleted_at` |
| `working_hours` | `20260623200000_salon_full_schema.sql` | Yes | Owner/manager manage; public SELECT | `UNIQUE(salon_id, day_of_week)` |
| `services` | `20260623210000_services_schema.sql` + FTS | Yes | Owner/manager manage; public SELECT (active only) | GIN trigram + `search_vector`. **`category` is free text, not a FK** — see Part 5 |
| `staff_profiles` | `20260623220000_staff_management.sql` + commissions + public-select | Yes | Owner manage; manager/staff view; own-profile self-update (role immutable); public SELECT (active only) | `idx_staff_invitation_token` UNIQUE. **Known tech-debt (in-migration comment)**: public SELECT policy exposes `invitation_token` to any reader |
| `staff_services` | `20260623220000_staff_management.sql` | Yes | Owner/manager manage; public SELECT | `UNIQUE(staff_id,service_id)`. **Gap**: no index on `salon_id` |
| `staff_working_hours` | `20260624080000_availability_advanced.sql` | Yes | Owner/manager manage; staff self-manage; public SELECT | `UNIQUE(staff_id,day_of_week)`. **Gap**: no index on `salon_id` |
| `staff_breaks` | same | Yes | Owner/manager manage; staff self-manage; public SELECT | **Gap**: no index on `salon_id` |
| `availability_overrides` | `20260623230000_availability_overrides.sql` | Yes | Owner/manager manage; public SELECT | `idx_availability_date(salon_id,staff_id,date)` |
| `availability_exceptions` | `20260624080000_availability_advanced.sql` | Yes | Owner/manager manage; staff self-manage; public SELECT | Seeded with 2026 Burundi public holidays at migration time |

### 3.3 Booking

| Table | Migration | SD | RLS | Idx / notes |
|---|---|---|---|---|
| `bookings` | `20260623240000_bookings_schema.sql` | Yes | Owner/manager full; staff own (select+update); client own SELECT; **no client INSERT policy** — creation is Edge-Function-only for atomic slot locking | `CONSTRAINT uq_practitioner_slot UNIQUE(practitioner_id,start_time)` — the slot-conflict guarantee; `idempotency_key UNIQUE`. Auto-cancel cron for stale `pending_payment` (>5 min) |
| `client_contacts` | `20260624090000_phase3a_schema.sql` | Yes | Owner/manager only (private CRM list, no client/staff visibility) | `idx_contacts_referral` UNIQUE |

### 3.4 Payments

| Table | Migration | SD | RLS | Idx / notes |
|---|---|---|---|---|
| `transactions` | `20260623250000_transactions_schema.sql` | Yes | **Owner-only** SELECT (not manager — R07 financial isolation); client own via booking join; no client write | `idempotency_key UNIQUE`, `leapa_reference UNIQUE` |
| `proxipay_sessions` | `20260702120000_proxipay_sessions.sql` | **No** (ephemeral, `expires_at`-driven) | Salon staff SELECT; pending+not-expired public SELECT; **no INSERT/UPDATE policy for `authenticated` at all** — functionally `WITH CHECK (FALSE)` by omission, enforced structurally | In `supabase_realtime` publication |
| `subscription_plans` | `20260627140000_phase6_subscriptions_billing.sql` | No (`is_active` flag instead) | Public SELECT (active only) | Global catalog: free/pro/premium |
| `invoices` | same | Yes | Owner-only | `reference UNIQUE`. Versioned via `entity_versions` (substitutes for the non-existent `subscriptions` table, per migration comment) |
| `staff_commissions` | `20260627130000_phase5_team_commissions.sql` | Yes | Owner manage; staff **own-only** SELECT (R11 isolation — never sees a colleague's commission) | `booking_id UNIQUE` |
| `rate_limit_buckets` | `20260627150000_adv6_security_hardening.sql` | No | RLS enabled with **zero** policies for any role — default-deny for everyone except service_role | Composite `PRIMARY KEY(key, window_start)`, no surrogate id |

### 3.5 Loyalty / Marketing

| Table | Migration | SD | RLS | Idx / notes |
|---|---|---|---|---|
| `loyalty_programs` | `20260624090000_phase3a_schema.sql` | Yes | Owner/manager manage; public SELECT (active) | 1:1 via `UNIQUE(salon_id)` |
| `loyalty_cards` | same | Yes | Client own SELECT; salon (owner/manager/**staff**) manage — staff can stamp/redeem directly | `UNIQUE(salon_id,client_id)` |
| `loyalty_stamp_logs` | same | No (append-only ledger) | Salon (owner/manager/staff) manage; client own SELECT | Populated only via RPCs |
| `loyalty_qr_tokens` | `20260627100000_phase3b_loyalty_qr.sql` | No (ephemeral, `expires_at`-driven, 10min default) | Client insert/select own; **no UPDATE policy** — only `validate-qr` (service_role) marks used | |
| `referrals` | `20260624090000_phase3a_schema.sql` + fixup | **No** — **tech debt: only loyalty/marketing table without `deleted_at`**, no way to soft-delete a stale/spam referral | Own referrals (`referrer_id OR referred_id = auth.uid()`) | `referral_token UNIQUE` |
| `promotions` | same | Yes | Owner/manager manage; public SELECT (active, not expired) | `idx_promo_salon_active` |

### 3.6 Reviews

| Table | Migration | SD | RLS | Idx / notes |
|---|---|---|---|---|
| `reviews` | `20260624090000_phase3a_schema.sql` | Yes | Client create (own completed booking only) + limited self-update (30 days, before owner reply); owner reply (column-restricted); public SELECT (not flagged) | `booking_id UNIQUE`. Column-level write protection via `protect_review_columns()` trigger (client can only touch rating/comment/is_anonymous; owner only owner_reply/owner_replied_at/is_flagged) |
| `review_media` | same | Yes | Client manages own (via review join); public SELECT | |

### 3.7 Marketing / Journey

| Table | Migration | SD | RLS | Idx / notes |
|---|---|---|---|---|
| `owner_journey_progress` | `20260624090000_phase3a_schema.sql` | **No** — **tech debt**, same 1:1-core-table gap as `salon_settings` | Owner-only (`owner_id=auth.uid()`) | Generated columns (`completed_steps`, `completion_pct`). In `supabase_realtime` publication |

### 3.8 Automation

| Table | Migration | SD | RLS | Idx / notes |
|---|---|---|---|---|
| `automation_trigger_types` | `20260629140000_automation_engine.sql` | No (global catalog) | Read-all | 8 seeded rows, `wired` flag (false = no runtime hookup yet — see `subscription.expiring`) |
| `automation_action_types` | same | No | Read-all | 8 seeded rows, `implemented` flag |
| `automation_workflows` | same | Yes | Owner/manager CRUD; **`is_system=TRUE` rows cannot be updated/deleted by anyone but service_role** (enforced in the RLS predicate itself) | **Bug**: no `updated_at` trigger despite the column |
| `automation_conditions` | same | No (cascade-deleted with workflow) | Same `is_system` guard via EXISTS-join to parent workflow | |
| `automation_actions` | same | No (cascade-deleted) | Same `is_system` guard | |
| `automation_execution_logs` | same | No (append-only) | Owner/manager SELECT only; writes are service_role only | |
| `automation_action_runs` | same | No (transient queue) | Owner/manager SELECT only | `idx_automation_action_runs_due(status,scheduled_at)`. **Gap**: no index on `salon_id` |

### 3.9 Notifications

| Table | Migration | SD | RLS | Idx / notes |
|---|---|---|---|---|
| `notification_quota` | `20260623260000_notification_quota.sql` | No (rolling window) | Owner/manager SELECT; writes only via `check_and_increment_promo_quota()` | Composite `PRIMARY KEY(salon_id,channel,window_start)` |
| `notification_templates` | `20260624060000_notifications_schema.sql` | Yes | Public SELECT (active); no client writes | `event_type UNIQUE`, 12 seeded event types |
| `notification_logs` | same | Yes | Own SELECT/UPDATE (mark-read); owner/manager salon-wide SELECT; no client INSERT (service_role only) | **Gap**: no index on `salon_id` despite being used in the owner/manager policy |
| `notification_preferences` | same | Yes | Own only (`FOR ALL`) | 1:1 via `UNIQUE(user_id)` |

### 3.10 Ops / Platform

| Table | Migration | SD | RLS | Idx / notes |
|---|---|---|---|---|
| `activity_logs` | `20260622182007_foundation.sql` + `audit_enterprise` | No (immutable audit trail, by design) | Self-INSERT restricted to a **whitelist of `type_action` values** (~27, grown across 4 migrations); owner/manager SELECT; **no UPDATE/DELETE policy anywhere** | Feeds `mv_audit_stats` (hourly refresh via pg_cron) |
| `entity_versions` | `20260629120000_entity_versioning.sql` | No (immutable ledger) | Owner/manager SELECT; writes only via `create_entity_version()` | `UNIQUE(entity_type,entity_id,version_number)`. Versions `services` and `invoices` (substituted for the non-existent `subscriptions` table) |
| `backup_jobs` | `20260630100200_phase3_backup.sql` | No | Owner/manager SELECT; writes only via `create-backup` | Companion Storage bucket `kynza-backups`, owner-only read |
| `document_templates` | `20260630100300_phase3_document_templates.sql` | Yes | Owner/manager full; staff SELECT | `UNIQUE(salon_id,default) WHERE is_default` enforces one default per type. Auto-seeded 3 templates/salon |
| `maintenance_windows` | `20260630110100_phase4_maintenance.sql` | No | Authenticated SELECT (any); admin writes via service_role | No `salon_id` column — uses `affected_salon_ids UUID[]` + `affects_all` instead. **Minor gap**: no GIN index on that array |
| `feature_flags` | `20260630110000_phase4_feature_flags.sql` | No | Authenticated SELECT; admin writes | `key UNIQUE`, 5 seeded rows (see Part 6) |
| `salon_feature_overrides` | same | No | Owner full; manager SELECT | `UNIQUE(salon_id,flag_key)`. Only table using plain `CREATE INDEX` (not `IF NOT EXISTS`) |
| `app_versions` | `20260630110200_phase4_app_versions.sql` | No | Authenticated SELECT; admin writes | `UNIQUE(platform,version_code)`, seeded 1.0.0 android/ios |
| `search_logs` | `20260627160000_adv3_search_logs.sql` | No | **Own INSERT only — no SELECT policy at all**, not even for the writer; aggregate exposure only via a non-`security_invoker` view | |

## 4. Cross-cutting Tech Debt (found during this audit)

**RLS coverage**: all 55 tables have `ENABLE ROW LEVEL SECURITY` — **zero missing-RLS tables**.
This corrects and reaffirms `docs/PRODUCTION_CHECKLIST.md`'s prior "32/32" claim at a higher,
now-accurate count (see Part 14 addendum).

**Missing `deleted_at` that IS a real gap** (as opposed to legitimate append-only/ephemeral/
catalog tables, which correctly don't have one):
- `salon_settings`, `owner_journey_progress` — both 1:1-with-salon tables, inconsistent with
  every other "core" salon table.
- `referrals` — the only loyalty/marketing table without one.

**Missing `updated_at` trigger despite having the column** (silently stale column — a real
correctness bug, not a design choice):
- `salon_settings`, `permission_groups`, `automation_workflows`.

**Missing index on a `salon_id` FK column**:
- `staff_services`, `staff_working_hours`, `staff_breaks`, `automation_action_runs`,
  `notification_logs` (nullable `salon_id`, used in the owner/manager SELECT policy).

**Other structural notes**:
- `salons.owner_id` is used throughout RLS/insert checks but is **not a declared FK** and has no
  index.
- `staff_profiles`' public-SELECT policy exposes `invitation_token` to any reader (flagged
  in-migration by the original author, not newly discovered).

All items above are appended to `docs/PRODUCTION_CHECKLIST.md` (§14 addendum) as tracked tech
debt — **not fixed as part of this documentation pass**, per the additive-only constraint.

## 5. Contraintes & Edge Cases

- `automation_conditions`/`automation_actions` have no `salon_id` column directly — tenant
  isolation is enforced transitively via an `EXISTS` join to the parent `automation_workflows`
  row. A future direct query against these tables must always join through the workflow, never
  assume a `salon_id` column exists.
- `proxipay_sessions` and `loyalty_qr_tokens` are both RLS-locked against direct client
  mutation — any new client-facing ProxiPay/QR feature must go through an Edge Function, never a
  direct `.insert()`/`.update()` from Flutter.
- `bookings.idempotency_key` and `transactions.idempotency_key` are separate unique keys on
  separate tables — do not conflate them when debugging a duplicate-payment report.

## 6. Sécurité

See `docs/SECURITY.md` for the `has_role()` pattern and JWT claim design. Table-specific
exceptions to the standard owner/manager/staff/client pattern are called out inline in §3 above
(e.g. `transactions` is owner-only, not manager; `staff_commissions` is staff-own-only).

## 7. Performance

### Index optimization candidates (documented, not applied)

A draft migration adding the 5 missing FK indexes identified in §4 is available at
`supabase/migrations/20260703120000_indexes_optimization.sql` — **not run against the remote**,
gated for manual review per the approved plan (this repo has no local Supabase/Docker stack; any
`db push` hits the live project directly).

### BRIN candidates for time-series tables

`activity_logs`, `automation_execution_logs`, and `entity_versions` are high-insert-volume,
append-only, time-ordered tables. A `BRIN` index on `created_at` (in addition to the existing
B-tree composite indexes) would be cheaper to maintain than a second B-tree for pure range scans
(e.g. "all logs from the last 30 days") once these tables reach hundreds of thousands of rows —
not yet necessary at current data volumes, tracked as a future optimization, not applied here.

### Connection pooling

Supabase's default pgbouncer runs in **transaction mode**. Edge Functions using
`createServiceRoleClient()` open a new Postgres connection per invocation via PostgREST/pooler —
this is fine for the current traffic profile but means session-level features (e.g. advisory
locks held across statements) cannot be relied on inside a single Edge Function invocation beyond
one transaction. `bookings`' slot-lock (`BEGIN → SELECT ... FOR UPDATE → INSERT → COMMIT`) is
correctly scoped to a single transaction for this reason.

## 8. Stratégie de tests

No dedicated SQL/migration test suite exists. RLS policy correctness is currently verified only
implicitly, through the 244 Flutter tests exercising repository calls against the real remote
project. Recommended (not yet implemented): `pgTAP` policy tests per table, especially for the
tables with unusual RLS shapes flagged in §3 (`transactions` owner-only, `proxipay_sessions`
policy-by-omission, `staff_commissions` own-only).

## 9. Documentation associée

- `docs/ARCHITECTURE.md` §4 — condensed patterns (multi-tenancy, RLS, soft-delete, auto-seed).
- `docs/SECURITY.md` — `has_role()` detail, RLS policy examples.
- `docs/EDGE_FUNCTIONS_REFERENCE.md` — which functions read/write which tables.
- `docs/CATALOG_ARCHITECTURE.md` (Phase C) — the `services.category` free-text gap becomes the
  starting point for the new `categories`/`service_variants` design.
- `docs/PRODUCTION_CHECKLIST.md` — tech-debt items from §4 appended there.

## 10. Critères d'acceptation

- [x] All 55 tables appear in the ERD with correct FKs (`notification_templates` was found
      missing from `erd.mermaid` during Phase 2's independent re-verification and added back —
      see `docs/audit/SCHEMA_RECONCILIATION_REPORT.md`).
- [x] Every table has documented RLS status — 55/55 have RLS enabled, verified (not assumed).
- [x] Index recommendations reference real gaps found in the actual migrations, not generic advice.
- [x] Discrepancy with the prior "~47 tables" figure explicitly reconciled (§2), not silently corrected.

## 11. Livrables

- `docs/DATABASE_ARCHITECTURE.md` (this file)
- `docs/diagrams/erd.mermaid`
- `supabase/migrations/20260703120000_indexes_optimization.sql` (drafted, **not applied**)
- Tech-debt items appended to `docs/PRODUCTION_CHECKLIST.md`
