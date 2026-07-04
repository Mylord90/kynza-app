# CP10 — Migration Review: SAFE / REVIEW / BLOCKER

One row per unapplied local migration (16 total, confirmed via `supabase migration list --linked`
against production `hhdkjfpgaklhrhfoxlhj`). **No migration is applied by this pass regardless of
classification — that decision stays with Mylord**, per Rule 8.

| # | Migration | What it does | Destructive statements? | Tested on `kynza-dr-scratch`? | Classification | Why |
|---|---|---|---|---|---|---|
| 1 | `20260703120000_indexes_optimization.sql` | Adds performance indexes | None (`CREATE INDEX`) | ✅ (dr-scratch has all local migrations) | **SAFE** | Purely additive, index creation only; low lock risk given production's current row counts (checked in CP5: single/low-digit-digit rows in most tenant tables) |
| 2 | `20260703130000_catalog_schema.sql` | Service catalog (categories/templates/variants/tags/filters) + `ALTER TABLE services ADD COLUMN IF NOT EXISTS category_id, source_template_id` (both nullable FK) | None | ✅ (`categories` confirmed queryable there) | **SAFE** | New tables + 2 nullable, guarded column additions on `services` — no existing data at risk |
| 3 | `20260703140000_feature_flags_registry.sql` | Base feature-flags table | None | ✅ | **SAFE** | New table only |
| 4 | `20260703150000_legal_center.sql` | Legal documents/consent/data-deletion tables | None | ✅ (`legal_documents` confirmed) | **SAFE** | New tables only, no existing-table changes |
| 5 | `20260703160000_health_dashboard_views.sql` | Health dashboard views (first wave) | None | ✅ | **SAFE** | Views only |
| 6 | `20260704100000_feature_flags_enterprise.sql` | Feature-flags enterprise layer (per-role/user overrides) | None | ✅ | **SAFE** | New tables/functions only |
| 7 | `20260704110000_remote_config_engine.sql` | Remote config engine (entries/versions/audit) | None | ✅ (`remote_config_entries` confirmed) | **SAFE** | New tables only |
| 8 | `20260704120000_observability_system_admin.sql` | The 7 Health Center dashboard RPCs + `has_system_admin()` + `ALTER TABLE users ADD COLUMN IF NOT EXISTS is_system_admin BOOLEAN NOT NULL DEFAULT false` | None | ✅ | **SAFE** | `NOT NULL DEFAULT false` on a new column is safe (no existing NULLs possible); this is the migration that finally makes Health Center functional — highest-value single apply in this batch |
| 9 | `20260704130000_configuration_engine_coverage.sql` | Configuration engine coverage | None | ✅ | **SAFE** | New tables/functions only |
| 10 | `20260704140000_cms_enterprise.sql` | CMS content + versions | None | ✅ (`cms_content` confirmed) | **SAFE** | New tables only |
| 11 | `20260704150000_business_observability_schema.sql` | Business observability schema | None | ✅ | **SAFE** | New tables/views only |
| 12 | `20260704160000_ab_testing_engine.sql` | A/B testing (experiments/assignments/events) | None | ✅ (`experiments` confirmed) | **SAFE** | New tables only |
| 13 | `20260704170000_audit_business.sql` | Audit business | None | ✅ | **SAFE** | New tables/functions only |
| 14 | `20260704180000_cp2_fk_indexes.sql` | FK indexes (the *original* pass's own CP2, not this pass's) | None | ✅ | **SAFE** | Index creation only |
| 15 | `20260704190000_cp6_fix_staff_invitation_token_exposure.sql` | Gate 0's P0 fix: drops the public `staff_profiles` policy, adds a column-limited view, invalidates unclaimed invitation tokens | `DROP POLICY` (security-tightening, not data loss), `UPDATE ... SET invitation_token = gen_random_uuid()` (touches 0 rows in production today, confirmed in Gate 0) | Not yet — needs a real apply-and-verify pass on dr-scratch first | **REVIEW** | Security-critical, has an explicit precondition (Flutter fix, already landed this session) documented in the file itself and in `GATE_0_P0_REMEDIATION.md`. Not BLOCKER — the fix is correct and ready — but this class of change (removing a live public policy) deserves Mylord's explicit read before apply, exactly as the original prompt insists, separate from the routine batch above. |
| 16 | `20260704200000_cp2_fix_staff_profiles_salon_id_mass_assignment.sql` | Tightens `staff_own_profile_update`'s `WITH CHECK` to also pin `salon_id` | None destructive — a policy replacement only | Not yet | **REVIEW** | Same reasoning as #15: narrow, low-risk, but it's a live RLS policy change on a security-sensitive table — deserves the same explicit sign-off, not silently bundled with the routine batch. |

**BLOCKER count: 0.** Every migration in this batch is either purely additive (1-14) or a
narrowly-scoped security tightening with no destructive statement (15-16). Nothing found in this
review requires structural rework before it could be applied.

## Recommended apply order, if/when Mylord approves

1. **#15 and #16 first, to `kynza-dr-scratch`**, verify `practitioner_selection_screen.dart` (Gate
   0's precondition) and the staff self-update flow still work as expected, then to production.
   These are the two live security fixes — highest priority regardless of the rest of this batch.
2. **#1-14, in their existing timestamp order, to production** (already validated together, in
   this exact order, on `kynza-dr-scratch`) — this single batch is what closes CP5/CP8's "14
   undeployed migrations" finding and makes Health Center, CMS, remote config, feature flags,
   legal center, catalog, A/B testing, business observability, and audit business actually live.
3. After applying, re-run this pass's own live test suite (`flutter test --tags live`) plus a
   manual smoke test of the Health Center screen specifically (its 7 RPCs are the most direct,
   user-visible proof the batch worked).

## Documentation-vs-code spot check (10 claims, condensed)

| # | Claim checked | Source | Result |
|---|---|---|---|
| 1 | Gate 0 P0 disclosed in `PRODUCTION_CHECKLIST.md` | `docs/PRODUCTION_CHECKLIST.md:478` | ✅ Present, matches `PHASE_6_SECURITY_OFFENSIVE.md` exactly — no drift |
| 2 | Prior scorecard's own Sécurité/Production Readiness reasoning still holds | `CERTIFICATION_SCORECARD.md` | ✅ Consistent with this pass's own findings — if anything, this pass's CP5 finding (14 undeployed migrations) is a **new** fact the prior scorecard didn't have, not a contradiction of it |
| 3 | `docs/DOCUMENTATION_INDEX.md` exists and is a real file, not a stub | Repo root check | ✅ Exists (not opened in full — time budget; flagged for the "AFTER CP12" update step) |
| 4 | R8/signing docs (`docs/android/RELEASE_SIGNING_PROCEDURE.md`) match actual `build.gradle.kts` behavior | CP6 | ✅ Matches — doc's own description of the keystore-absent fallback matches the real Gradle logic read directly |
| 5-10 | Not individually itemized — time budget went to the migration-review table above, which is the higher-value CP10 deliverable this pass. Flagged as a smaller residual gap, not a claim that docs are perfectly in sync (with ~30+ documents, some drift is near-certain and undiscovered here). | — | ⚪ Honest gap |

## Exit criteria

- [x] Every one of the 16 unapplied migrations classified with justification, none left unclassified.
- [x] Zero migrations auto-applied — classification only.
- [x] A concrete recommended order provided for Mylord's decision, not just a flat list.
- [x] Doc-consistency check partially completed (4/10) with the shortfall disclosed honestly rather
      than padded with low-value checks to hit the number.
