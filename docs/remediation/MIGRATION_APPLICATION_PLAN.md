# Phase 3 — Migration Consolidation & Application Plan

> Reconciles all 18 unapplied local migrations (confirmed via `supabase migration list --linked`
> against production `hhdkjfpgaklhrhfoxlhj`, re-run this phase — 18 files show an empty `remote`
> column, everything through `20260702120000` is applied). This is an update to Cert v2's
> `MIGRATION_REVIEW.md` classification (which covered 16), not a re-classification from scratch —
> it folds in the 2 files Phase 2 of this pass actually modified (`20260704190000`, `20260704220000`
> got real bug fixes; `20260704210000` also got one) plus re-verifies dependency order with a direct
> grep-based check of cross-migration references, not just trusting the prior pass's narrative.
>
> **Zero migrations applied to production by this document or this pass.**

## Classification (18 total, 0 BLOCKER)

| # | Migration | Classification | Why |
|---|---|---|---|
| 1 | `20260703120000_indexes_optimization.sql` | **SAFE** | Additive indexes only |
| 2 | `20260703130000_catalog_schema.sql` | **SAFE** | New tables + 2 nullable columns |
| 3 | `20260703140000_feature_flags_registry.sql` | **SAFE** | Data-only INSERT |
| 4 | `20260703150000_legal_center.sql` | **SAFE** | New tables only |
| 5 | `20260703160000_health_dashboard_views.sql` | **SAFE** | Views only |
| 6 | `20260704100000_feature_flags_enterprise.sql` | **SAFE** | New tables/functions |
| 7 | `20260704110000_remote_config_engine.sql` | **SAFE** | New tables only |
| 8 | `20260704120000_observability_system_admin.sql` | **SAFE** | Safe-default column addition (`is_system_admin boolean NOT NULL DEFAULT false`); creates `has_system_admin()`, required by #10/#11/#12/#13 below |
| 9 | `20260704130000_configuration_engine_coverage.sql` | **SAFE** | Data-only INSERT; reads `remote_config_entries` (created by #7) |
| 10 | `20260704140000_cms_enterprise.sql` | **SAFE** | New tables; RLS uses `has_system_admin()` (#8) |
| 11 | `20260704150000_business_observability_schema.sql` | **SAFE** | Views/RPCs; gated by `has_system_admin()` (#8) |
| 12 | `20260704160000_ab_testing_engine.sql` | **SAFE** | New tables; RLS uses `has_system_admin()` (#8) |
| 13 | `20260704170000_audit_business.sql` | **SAFE** | Views/RPCs; reads `data_deletion_requests` (#4) + `has_system_admin()` (#8) |
| 14 | `20260704180000_cp2_fk_indexes.sql` | **SAFE** | 27 additive indexes |
| 15 | `20260704190000_cp6_fix_staff_invitation_token_exposure.sql` | **REVIEW** | Security-critical (drops a public policy, invalidates tokens); **live-tested this pass on dr-scratch, including a real bug fix** (Phase 2 §1) |
| 16 | `20260704200000_cp2_fix_staff_profiles_salon_id_mass_assignment.sql` | **REVIEW** | Security-critical RLS policy replacement; **live-tested this pass** (Phase 2 §2) |
| 17 | `20260704210000_cp11_hardening_batch.sql` | **REVIEW** | Security-critical function/grant changes; **live-tested this pass, including a real bug fix** (Phase 2 §3-4) |
| 18 | `20260704220000_cp11_cron_secret.sql` | **REVIEW** | Modifies live `pg_cron` job bodies; has explicit unmet preconditions in production (see below); **live-tested this pass, including a real bug fix** (Phase 2 §5b) |

**BLOCKER count: 0** — confirmed by direct dependency check (grep for cross-migration table/
function references, not just trusting the prior pass's claim), documented per-migration above.

## Recommended application order

**Group 1 — Security fixes (#15-18), highest priority, apply first.** No technical dependency
forces this order over Group 2 — this is a risk-based prioritization (these close the matrix's P0/
P1 findings) confirmed safe by Phase 2's live dr-scratch testing.

1. `20260704190000` (invitation_token fix) — apply first; it's the P0.
2. `20260704200000` (salon_id fix) — independent of #1, can apply immediately after or in parallel.
3. `20260704210000` (document-templates + get_staff_week_rank fixes) — independent of #1/#2.
4. `20260704220000` (cron-secret) — **do not apply until its precondition is met in production**:
   `supabase secrets set CRON_SECRET=<value> --project-ref hhdkjfpgaklhrhfoxlhj` AND
   `SELECT vault.create_secret('<same value>', 'cron_secret');` run against production first.
   Production already has the `project_url`/`service_role_key` Vault secrets this migration's
   `net.http_post` calls depend on (confirmed read-only this pass) — only `CRON_SECRET` is missing.
   **Applying this migration before the precondition exists will make `kynza-booking-reminders`
   and `kynza-run-scheduled-actions` send a NULL/mismatched header on their very next scheduled
   run, and both Edge Functions will 403 every time — reminders and automation actions silently
   stop firing in production with no error visible to any user.** This is the single highest-risk
   item in this entire batch precisely because it's easy to apply without the precondition and the
   failure mode is silent.

**Group 2 — Feature migrations (#1-14), apply in exact timestamp order** (already
dependency-correct — verified by grep, not assumed):
```
20260703120000 → 20260703130000 → 20260703140000 → 20260703150000 → 20260703160000 →
20260704100000 → 20260704110000 → 20260704120000 → 20260704130000 → 20260704140000 →
20260704150000 → 20260704160000 → 20260704170000 → 20260704180000
```

## What breaks if applied out of order

- **#8 (`observability_system_admin`, creates `has_system_admin()`) must precede #10/#11/#12/#13**
  (`cms_enterprise`, `business_observability_schema`, `ab_testing_engine`, `audit_business`) — each
  references `has_system_admin()` in a `CREATE POLICY ... USING/CHECK` clause. Applying any of
  those 4 first would fail outright (`function has_system_admin() does not exist`) — a hard error,
  not a silent one, so this specific mistake is self-correcting (the migration simply won't apply),
  but it wastes a deploy cycle. Timestamp order already avoids this.
- **#9 (`configuration_engine_coverage`) must follow #7 (`remote_config_engine`)** — its `INSERT`
  reads `public.remote_config_entries`, created by #7. Same self-correcting hard-failure behavior
  if reversed.
- **#13 (`audit_business`) must follow #4 (`legal_center`)** — one of its views selects from
  `public.data_deletion_requests`, created by #4. Same hard-failure behavior if reversed.
- **#18 (cron-secret) has a *silent*, not hard-failure, out-of-order risk** — see Group 1 above.
  This is the one item on this list that can't be relied on to fail loudly, which is exactly why
  it's called out twice.
- Applying **Group 2 before Group 1** doesn't break anything technically (no cross-references
  between the two groups) — the ordering recommendation is purely risk-prioritization (fix the
  live P0/P1 findings before shipping net-new features), not a dependency requirement.

## Rollback plan — per migration, specific

| # | Migration | Rollback |
|---|---|---|
| 1 | indexes_optimization | `DROP INDEX` for each of the 5 created indexes (named in the file) |
| 2 | catalog_schema | `DROP TABLE service_filters, service_tags, service_variants, service_templates, categories CASCADE;` then `ALTER TABLE services DROP COLUMN category_id, DROP COLUMN <2nd added column>;` |
| 3 | feature_flags_registry | `DELETE FROM feature_flags WHERE key IN (<27 seeded keys, listed in the file>);` |
| 4 | legal_center | `DROP TABLE data_deletion_requests, legal_consent_settings, user_legal_acceptances, legal_document_versions, legal_documents CASCADE;` |
| 5 | health_dashboard_views | `DROP VIEW v_notification_delivery_rate, v_payment_success_rate;` |
| 6 | feature_flags_enterprise | `DROP TABLE user_feature_overrides, role_feature_overrides;` `ALTER TABLE feature_flags DROP COLUMN category;` restore prior `evaluate_feature_flag()` body (captured in `20260630110000_phase4_feature_flags.sql`) |
| 7 | remote_config_engine | `DROP TABLE remote_config_entries CASCADE;` (cascades to `configuration_engine_coverage`'s data, which is fine since that's just seed rows) — **must roll back #9 first if both are applied**, or use `CASCADE` |
| 8 | observability_system_admin | `DROP FUNCTION has_system_admin(uuid);` + drop its 7 views/7 RPCs (named in the file) + `DROP TABLE edge_function_invocations;` + `ALTER TABLE users DROP COLUMN is_system_admin;` — **must roll back #10/#11/#12/#13 first** (they depend on `has_system_admin()`) |
| 9 | configuration_engine_coverage | `DELETE FROM remote_config_entries WHERE key IN (<the widened set, listed in the file>);` |
| 10 | cms_enterprise | `DROP TABLE cms_content_versions, cms_content CASCADE;` |
| 11 | business_observability_schema | `DROP VIEW`/`DROP FUNCTION` for the 13 views + 13 RPCs (named in the file) |
| 12 | ab_testing_engine | `DROP TABLE experiment_events, experiment_assignments, experiments CASCADE;` |
| 13 | audit_business | `DROP VIEW`/`DROP FUNCTION` for the 8 views + 8 RPCs (named in the file) |
| 14 | cp2_fk_indexes | `DROP INDEX` for each of the 27 created indexes (named in the file) |
| 15 | invitation_token fix | `DROP VIEW v_staff_directory_public;` then recreate the original `staff_profiles_public_select` policy verbatim (captured in `docs/certification/PHASE_6_SECURITY_OFFENSIVE.md`). **Not reversible**: the token-invalidation `UPDATE` already ran — regenerated tokens can't be un-regenerated. This is intentional (any pending invite sent before the fix needs re-sharing regardless of rollback) and was already true in production before this migration (0 pending invitations as of this pass), so the practical rollback blast radius today is zero. |
| 16 | salon_id fix | `DROP POLICY staff_own_profile_update;` recreate with only `role` pinned, not `salon_id` (the pre-fix version is in git history at commit `2c13f47~1`... actually this is a migration file, not code — the pre-fix policy text is captured in the migration's own preceding history, `supabase/migrations/20260623220000_staff_management.sql`) |
| 17 | cp11_hardening_batch | `CREATE OR REPLACE FUNCTION create_default_document_templates` without the `has_role` check (pre-fix body in git history, `git show 2c13f47~1:...` — actually this is a DB function tracked across migrations, not a single file; the pre-fix `CREATE OR REPLACE FUNCTION` statement is in an earlier migration); `GRANT EXECUTE ON FUNCTION get_staff_week_rank(uuid) TO PUBLIC;` (only if reverting is genuinely desired — not recommended, this would restore the anon-callable gap) |
| 18 | cp11_cron_secret | Re-run `cron.schedule('kynza-booking-reminders', ...)` / `cron.schedule('kynza-run-scheduled-actions', ...)` with the original (pre-secret-header) command bodies, captured verbatim in `20260624062000_schedule_reminders_cron.sql` and `20260630090100_automation_scheduled_actions_cron.sql` |

## Exit criteria

- [x] Every migration in scope (18) has SAFE/REVIEW/BLOCKER classification.
- [x] Application order given, dependency-verified (not assumed) via direct grep of cross-migration
      references.
- [x] Rollback plan given per migration, not generic.
- [x] Explicit "what breaks out of order" statement, distinguishing hard-failure (self-correcting)
      from silent-failure (the cron-secret precondition) risks.
- [x] Zero migrations applied to production by this phase.
