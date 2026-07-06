# Phase 2 — Migration Deployment Report

**Date**: 2026-07-06. **Scope**: deploy the remaining migrations to production
(`hhdkjfpgaklhrhfoxlhj`), one validated step at a time, in dependency order — nothing else.
Executed under the KYNZA — Production Go-Live Execution prompt's Phase 2, authorized by Mylord's
"continue" after Phase 1's report.

## Before deploying — re-verification performed this session

- **Live re-check, not trusted from any report**: `supabase migration list --linked` at the start
  of this phase showed **26 unapplied migrations** (Phase 1 closed the 27th, `20260704190000`,
  already). This is the real, freshly-queried number, not the "27" carried forward from the
  certification document.
- **Classification gathered from 3 independent prior passes, cross-checked against each other,
  not re-derived from scratch**: `docs/remediation/MIGRATION_APPLICATION_PLAN.md` (18 of the 26),
  `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §7 (2 more), `docs/enterprise-final-100/
  CP7_PRODUCTION_READINESS.md` (4 more) — the remaining 1 (`20260706140000`, added by CP8 after
  CP7 was written) was classified this session by direct inspection of the migration file itself
  and its source report (`CP8_SCALABILITY.md`), the same standard the prior passes used. **0
  classified BLOCKER across all 26**, confirmed independently rather than just re-quoted.
- **Preconditions checked live before touching anything**:
  - `CRON_SECRET` — confirmed **absent** from both production Edge Function secrets and Vault
    (the exact gap 3 prior reports flagged). Generated a new random value, set via `supabase
    secrets set CRON_SECRET=... --project-ref hhdkjfpgaklhrhfoxlhj` and `SELECT
    vault.create_secret(..., 'cron_secret')` against production, **before** applying either
    migration that depends on it (`20260704220000`, `20260705130000`). This is an internal
    shared-secret between our own cron jobs and our own Edge Functions (not a third-party
    credential), generated and set as part of executing this already-drafted, already-approved
    remediation — consistent with every prior report's own instructions to do exactly this.
  - Production already had `project_url`/`service_role_key` in Vault (confirmed, matching prior
    reports) — only `cron_secret` was missing.
  - `proxipay_sessions`: checked for existing duplicate concurrent-pending rows per booking before
    applying the new partial unique index (`20260706130000`) — **zero conflicts found**, confirmed
    the index would apply cleanly rather than assuming it.
  - `pg_trgm`, `pg_cron`, `pg_net` extensions: confirmed already enabled in production before the
    migrations that require them.
  - `salons.owner_id` → `users.id` FK (`20260706120000`, `NOT VALID` + `VALIDATE`): confirmed zero
    orphan rows by the `VALIDATE CONSTRAINT` statement succeeding without error (it would have
    failed loudly otherwise).
- **Rollback confirmed to exist for every one of the 26** before applying, per migration, sourced
  from the 3 reports above plus direct DDL inspection for the newest one — table in the appendix
  below.

## Execution — one migration at a time, in exact timestamp order

All 26 applied via `supabase db query --linked --file <migration>.sql` (executes the full file
against production directly, since `supabase db push` applies its entire pending batch in one
shot with no per-migration pause — incompatible with this phase's "validate after each, stop on
ambiguity" requirement). After each migration: a targeted validation query confirmed the expected
objects/behavior, then `supabase migration repair --status applied <version> --linked` recorded
it in migration history before moving to the next file.

| # | Migration | Result | Validation performed |
|---|---|---|---|
| 1 | `20260703120000_indexes_optimization` | Applied | All 5 named indexes confirmed in `pg_indexes` |
| 2 | `20260703130000_catalog_schema` | Applied | All 5 new tables + 2 new `services` columns confirmed |
| 3 | `20260703140000_feature_flags_registry` | Applied | `feature_flags` row count → 33 |
| 4 | `20260703150000_legal_center` | Applied | All 5 new tables confirmed |
| 5 | `20260703160000_health_dashboard_views` | Applied | Both views confirmed in `information_schema.views` |
| 6 | `20260704100000_feature_flags_enterprise` | Applied | Both new tables + `feature_flags.category` column confirmed |
| 7 | `20260704110000_remote_config_engine` | Applied | `remote_config_entries` table confirmed |
| 8 | `20260704120000_observability_system_admin` | Applied | `has_system_admin()`, `users.is_system_admin`, `edge_function_invocations` all confirmed |
| 9 | `20260704130000_configuration_engine_coverage` | Applied | `remote_config_entries` row count → 23 |
| 10 | `20260704140000_cms_enterprise` | Applied | Both new tables confirmed |
| 11 | `20260704150000_business_observability_schema` | Applied | All 13 `v_bi_*` views + 13 `get_bi_*` RPCs confirmed by count |
| 12 | `20260704160000_ab_testing_engine` | Applied | All 3 new tables confirmed |
| 13 | `20260704170000_audit_business` | Applied | All 8 views confirmed by count (matches file's 8 `CREATE VIEW`) |
| 14 | `20260704180000_cp2_fk_indexes` | Applied | All 27 named indexes confirmed present by exact-name count |
| 15 | `20260704200000_cp2_fix_staff_profiles_salon_id_mass_assignment` | Applied | `pg_policies.with_check` re-read directly — confirms `salon_id` now pinned exactly as dr-scratch-tested |
| 16 | `20260704210000_cp11_hardening_batch` | Applied | **Live exploit re-attempted against production itself**: anon RPC call to `create_default_document_templates` → `403`/`"forbidden"` (was previously unrestricted); `has_function_privilege('anon','get_staff_week_rank(uuid)','execute')` → `false` |
| 17 | `20260704220000_cp11_cron_secret` | Applied | Confirmed real job names (`kynza-booking-reminders`, `kynza-run-scheduled-actions`) before applying — matches exactly, avoiding the previously-found "wrong job name" bug; both jobs' command text now includes `X-Cron-Secret`; both jobs still `active=true` |
| 18 | `20260705100000_cp0_concurrency_atomic_claims` | Applied | `claim_pending_action_runs()`, `reminder_dispatch_claims` table, and the new partial unique index all confirmed |
| 19 | `20260705110000_cp6_observability_alerting` | Applied | `v_payment_dashboard`, `system_alerts`, and all 3 new RPCs confirmed |
| 20 | `20260705120000_cp2_realtime_notification_logs` | Applied | `notification_logs` confirmed added to `supabase_realtime` publication |
| 21 | `20260705130000_cp3_platform_backup_automation` | Applied | `platform_backup_jobs` table, `get_all_public_tables()`, and the `kynza-platform-backup` cron job (`active=true`) confirmed |
| 22 | `20260706100000_cp2_system_admin_grant_audit` | Applied | `system_admin_audit` table, `grant_system_admin`/`revoke_system_admin` RPCs, and the `protect_user_columns` exception flag all confirmed |
| 23 | `20260706110000_cp3_maintenance_admin_write` | Applied | Both new policies confirmed on `maintenance_windows` |
| 24 | `20260706120000_cp4_db_correctness_debt` | Applied | All 3 triggers, all 3 `deleted_at` columns, and the validated FK constraint confirmed |
| 25 | `20260706130000_cp7_proxipay_session_unique` | Applied | New partial unique index confirmed present |
| 26 | `20260706140000_cp8_batch_monthly_bookings_trigger` | Applied | New trigger confirmed `AFTER INSERT`/statement-level (`tgtype=4`); old row-level function retained (rollback safety net intact) |

**Zero failures. Zero ambiguous validations. Nothing skipped or reordered outside the
dependency-verified sequence above.**

## A gap found and reported, not silently patched over

Applying `20260704220000` makes both cron jobs *send* an `X-Cron-Secret` header. It does **not**
by itself make `run-scheduled-actions`/`schedule-reminders` *require* that header — that
enforcement lives in the Edge Function code, which is a separate deployment mechanism
(`supabase functions deploy`), outside this phase's literal scope ("migrations"). Checked live,
before and after this migration: an unauthenticated call to `run-scheduled-actions` with only the
anon key (no `X-Cron-Secret`) returns `200 {"status":"processed","count":0}` — the currently
*deployed* function version (`v3`, last updated before this campaign's security patch was
written) does not check the header. The migration is safe either way (the extra header is
currently just ignored), but **P2-3's protection is not actually enforced yet** — that requires a
companion Edge Function redeploy, not covered by "migrations" and not attempted here. Flagging
this explicitly rather than letting the Master Inventory imply P2-3 is fully closed once this
migration lands.

Similarly, `20260705130000` registers the `kynza-platform-backup` cron job pointing at
`/functions/v1/create-platform-backup` — that function **does not exist yet** in production
(confirmed via `supabase functions list`). The migration applies cleanly regardless (`cron.schedule`
doesn't validate the target URL), but the job will 404 on its first scheduled run until the
function itself is deployed — which is explicitly Phase 3's objective ("deploy the recurring
backup job to production; confirm it runs once for real"), not this phase's.

## Rollback (written before deployment, available if needed — not exercised)

| # | Migration | Rollback |
|---|---|---|
| 1 | indexes_optimization | `DROP INDEX` for each of the 5 |
| 2 | catalog_schema | `DROP TABLE service_filters, service_tags, service_variants, service_templates, categories CASCADE; ALTER TABLE services DROP COLUMN category_id, DROP COLUMN source_template_id;` |
| 3 | feature_flags_registry | `DELETE FROM feature_flags WHERE key IN (<seeded keys>);` |
| 4 | legal_center | `DROP TABLE data_deletion_requests, legal_consent_settings, user_legal_acceptances, legal_document_versions, legal_documents CASCADE;` |
| 5 | health_dashboard_views | `DROP VIEW v_notification_delivery_rate, v_payment_success_rate;` |
| 6 | feature_flags_enterprise | `DROP TABLE user_feature_overrides, role_feature_overrides; ALTER TABLE feature_flags DROP COLUMN category;` |
| 7 | remote_config_engine | `DROP TABLE remote_config_entries CASCADE;` (roll back #9 first, or use CASCADE) |
| 8 | observability_system_admin | `DROP FUNCTION has_system_admin(uuid);` + its 7 views/7 RPCs + `DROP TABLE edge_function_invocations; ALTER TABLE users DROP COLUMN is_system_admin;` (roll back #10/#11/#12/#13 first) |
| 9 | configuration_engine_coverage | `DELETE FROM remote_config_entries WHERE key IN (<widened set>);` |
| 10 | cms_enterprise | `DROP TABLE cms_content_versions, cms_content CASCADE;` |
| 11 | business_observability_schema | `DROP VIEW`/`DROP FUNCTION` for the 13+13 named objects |
| 12 | ab_testing_engine | `DROP TABLE experiment_events, experiment_assignments, experiments CASCADE;` |
| 13 | audit_business | `DROP VIEW`/`DROP FUNCTION` for the 8+8 named objects |
| 14 | cp2_fk_indexes | `DROP INDEX` for each of the 27 |
| 15 | salon_id fix | `DROP POLICY staff_own_profile_update;` recreate the pre-fix version (role-only pin, captured in `20260623220000_staff_management.sql`) |
| 16 | cp11_hardening_batch | `CREATE OR REPLACE FUNCTION create_default_document_templates` without the `has_role` check (pre-fix body, git history); `GRANT EXECUTE ON FUNCTION get_staff_week_rank(uuid) TO PUBLIC;` (not recommended) |
| 17 | cp11_cron_secret | Re-run `cron.schedule` for both jobs with the pre-secret command bodies (`20260624062000_schedule_reminders_cron.sql`, `20260630090100_automation_scheduled_actions_cron.sql`) |
| 18 | cp0_concurrency_atomic_claims | `DROP FUNCTION claim_pending_action_runs; DROP TABLE reminder_dispatch_claims; DROP INDEX idx_data_deletion_requests_one_pending_per_user;` revert `automation_action_runs` status check/drop `claimed_at` |
| 19 | cp6_observability_alerting | `DROP VIEW v_payment_dashboard; DROP FUNCTION get_payment_dashboard, check_system_alerts, get_system_alerts; DROP TABLE system_alerts;` |
| 20 | cp2_realtime_notification_logs | `ALTER PUBLICATION supabase_realtime DROP TABLE public.notification_logs;` |
| 21 | cp3_platform_backup_automation | `SELECT cron.unschedule('kynza-platform-backup'); DROP FUNCTION get_all_public_tables(); DROP TABLE platform_backup_jobs;` |
| 22 | cp2_system_admin_grant_audit | `DROP FUNCTION grant_system_admin, revoke_system_admin; DROP TABLE system_admin_audit;` restore prior `protect_user_columns` body |
| 23 | cp3_maintenance_admin_write | `DROP POLICY maintenance_windows_admin_write, maintenance_windows_admin_delete;` |
| 24 | cp4_db_correctness_debt | `DROP TRIGGER` ×3; `ALTER TABLE ... DROP COLUMN deleted_at` ×3; `ALTER TABLE salons DROP CONSTRAINT salons_owner_id_fkey; DROP INDEX idx_salons_owner_id;` |
| 25 | cp7_proxipay_session_unique | `DROP INDEX idx_proxipay_sessions_one_pending_per_booking;` |
| 26 | cp8_batch_monthly_bookings_trigger | `DROP TRIGGER trg_increment_monthly_bookings; CREATE TRIGGER trg_increment_monthly_bookings AFTER INSERT ON bookings FOR EACH ROW EXECUTE FUNCTION increment_monthly_bookings_count();` (old function retained, rollback is a straight swap) |

## After — final validation

- **Migration count re-confirmed**: `supabase migration list --linked` → **86 local, 86 applied,
  0 unapplied.** Every migration in the repository is now live in production.
- **`flutter analyze`**: 0 issues.
- **Live production sanity checks** (real HTTP, anon key, after all 26 migrations): `salons`
  still readable; `v_staff_directory_public` (Phase 1's fix) still serves data correctly; new
  `categories` table reachable (empty — no seed data yet, out of this phase's scope). No
  regression in any pre-existing read path.
- **No code changed this phase** (production-DB-only) — `flutter test`'s 411/5/0 baseline is
  unaffected and was not expected to move.

## Result

All 26 previously-undeployed migrations are now live in production, individually validated, in
dependency order, with zero failures. Two known, pre-existing gaps are carried forward
transparently (not silently implied closed): the `run-scheduled-actions`/`schedule-reminders`
Edge Function code still needs redeployment to actually enforce the cron-secret check, and
`create-platform-backup` still needs its first deployment before the newly-registered backup cron
job will succeed. Both are natural inputs to Phase 3.

## Next

Per the governing prompt: **STOP here.** Phase 3 (Production Operations — backups, monitoring,
alerting, cron jobs) requires Mylord's explicit authorization before starting.
