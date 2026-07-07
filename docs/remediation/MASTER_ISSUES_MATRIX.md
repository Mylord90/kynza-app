# KYNZA — Master Issues Matrix (Remediation v1, Phase 1)

> ## ⚠️ SUPERSEDED (2026-07-07)
> **This document is historical evidence only — it is no longer the canonical issue tracker.**
> It was last updated 2026-07-04 and was never revised after the 2026-07-06 go-live deployments
> closed several items still marked open below (see `docs/final-doc-verification/P0_VERIFICATION.md`
> and `P1_VERIFICATION.md` for the live re-verification that found this). **The canonical, actively-
> maintained Master Inventory is `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2** — consult
> that document for current issue status. This file remains on disk, unmodified in its findings
> below except for the ID-collision correction noted at P2-22/P2-28, as the evidentiary record of
> the Remediation v1 pass itself. See `docs/governance/PHASE_1_DOCUMENTARY_UNIFICATION.md` for the
> full canonicalization ruling.

> Deduplicated union of every still-open finding from the 5 prior passes — Enterprise Architecture
> & Documentation Expansion ("Doc pass"), Enterprise Hardening & Production Readiness ("Hardening
> pass", tag `post-hardening-v1`), Backend Enterprise Completion ("Backend pass", tag
> `backend-complete-v1`), Enterprise Final Certification ("Cert v1", tag `enterprise-certified-v1`),
> Final Enterprise Verification v2 ("Cert v2", tag `enterprise-verified-v2`) — plus every dated
> update section in `docs/PRODUCTION_CHECKLIST.md`. Read in full by 4 parallel research passes plus
> a direct read of `PRODUCTION_CHECKLIST.md`; this document is the synthesis, not a re-audit.
>
> **Corroboration** next to an item's ID means how many of the 5 passes independently confirmed it
> (not just repeated it from a prior report) — a higher number is higher-confidence, per the
> remediation prompt's own instruction.

## How to read this matrix

Each item has: **ID**, **P0-P3**, **Title**, **Corroboration** (passes that independently found/
re-confirmed it), **Impact**, **Probability**, **Criticité** (Impact × Probability, qualitative),
**Preuve** (with source report cited), **Repro**, **Proposed fix**, **Validation method**, **Test
plan**, **Rollback plan**, **Status**, and for security items, **OWASP/MITRE mapping**.

**Status vocabulary** (per the remediation prompt's Rule): `open` / `fix drafted, awaiting
approval` / `fix applied — pending deploy` (n/a in this repo — a fix is either pure Flutter code,
in which case Phase 2 applies it directly, or it touches Supabase, in which case it stays
`drafted, awaiting approval` until Mylord approves) / `closed`.

## Executive summary

| Severity | Count | Of which already closed |
|---|---|---|
| P0 | 1 | 0 |
| P1 | 8 | 1 (Phase 0 backup, this pass) |
| P2 | 22 | 1 (P2-5, P2-5 ECR, 2026-07-07 — see entry for scope; P2-28 added same session, still open) |
| P3 | 19 | 5 (fixed in earlier passes, verified still true) |
| **Total distinct issues** | **50** | **7** |

---

## P0

### P0-1 — `staff_profiles.invitation_token` publicly readable (account-takeover vector)

- **Corroboration: 3 passes** — first found Cert v1/CP6 (`PHASE_6_SECURITY_OFFENSIVE.md`), fix
  drafted + Flutter precondition resolved by Cert v2/Gate 0 (`GATE_0_P0_REMEDIATION.md`),
  independently re-confirmed present via the RLS adversarial matrix in Cert v2/CP3
  (`CP3_RLS_ADVERSARIAL_MATRIX.md` — `staff_profiles` full-row read including `invitation_token`
  for owner/staff/client all succeed cross-tenant).
- **Impact**: Critical. `invitation_token` is the *sole* credential `accept-invitation` uses to
  bind any authenticated caller's account to a `staff_profiles` row (grants `staff` role +
  `salon_id` at that salon). Anyone who reads a pending invitation's token can hijack that staff
  identity at a salon they have no relationship to — full account takeover / cross-tenant identity
  impersonation.
- **Probability**: High. Exploitable by a single unauthenticated `curl` call; policy has been in
  production since the table was created (`hhdkjfpgaklhrhfoxlhj`).
- **Criticité**: **Critical** (Impact × Probability both high).
- **OWASP/MITRE**: OWASP API Security Top 10 2023 — **API3:2023 Broken Object Property Level
  Authorization** (excessive data exposure via row-level policy that can't hide columns) combined
  with **API1:2023 Broken Object Level Authorization** (no ownership check on `accept-invitation`
  beyond token possession). MITRE ATT&CK: **T1078 (Valid Accounts)** — token theft enables the
  adversary to obtain a valid, legitimate staff account context.
- **Preuve**: `pg_policy` metadata on `staff_profiles_public_select`: `USING ((deleted_at IS NULL)
  AND (is_active = true))`, `polroles` = `null` (applies to `PUBLIC`, including `anon`). Confirmed
  identical in production via read-only metadata inspection (Cert v1/CP6) and re-confirmed live on
  `kynza-dr-scratch` via the CP3 adversarial matrix (Cert v2). Production impact as of 2026-07-04:
  exactly 2 `staff_profiles` rows exist, both already `invitation_accepted_at IS NOT NULL` (Gate 0
  check) — no *currently* exploitable pending invitation in production today, but the policy itself
  remains live and would expose any *future* pending invitation the moment one is created.
- **Repro**:
  ```
  curl "$SB_URL/rest/v1/staff_profiles?select=id,display_name,invitation_token,phone&limit=3" \
    -H "apikey: <anon key>"
  → HTTP 200, invitation_token values returned, zero auth required
  ```
- **Proposed fix**: `supabase/migrations/20260704190000_cp6_fix_staff_invitation_token_exposure.sql`
  — drops the public policy, adds a column-limited view `v_staff_directory_public` (id, salon_id,
  role, display_name, avatar_url, bio, specialties, is_active, invitation_accepted_at — excludes
  `invitation_token`/`phone`/`invited_by`), and invalidates all unclaimed invitation tokens
  (`UPDATE ... SET invitation_token = gen_random_uuid() WHERE invitation_accepted_at IS NULL`).
  **Flutter precondition (the thing that blocked this for 2 passes) is resolved**: Gate 0 traced the
  one real consumer (`practitioner_selection_screen.dart`, via `bookingFlowProvider`) and re-pointed
  it at a new `publicSalonStaffProvider` reading the safe view; the other 11 call sites of
  `salonStaffProvider` all depend on unaffected role-gated policies. `flutter analyze`: 0 issues on
  both changed files.
- **Validation method**: Apply migration to `kynza-dr-scratch` first; re-run the exact `curl`
  repro above (expect 401/empty for the base table, safe columns only from the view); manually
  exercise `practitioner_selection_screen.dart`'s booking flow end-to-end on dr-scratch to confirm
  no regression.
- **Test plan**: (1) apply to dr-scratch, (2) re-run CP3's RLS adversarial matrix for
  `staff_profiles` specifically — expect the row to flip from "🔴 full row" to "✅ isolated columns
  only", (3) `flutter test` full suite (no regression expected, only 2 files touched), (4) manual
  practitioner-selection flow smoke test, (5) only then request Mylord's approval to apply to
  production.
- **Rollback plan**: `DROP VIEW v_staff_directory_public; CREATE POLICY staff_profiles_public_select
  ...` (recreate the original policy verbatim — captured in the migration's own down-comment) if
  the re-pointed screen breaks in an unforeseen way; revert the 2 Flutter files via `git revert`.
- **Status**: **fix drafted + live-tested this pass, awaiting Mylord's explicit approval**. Phase 2
  applied the fix to `kynza-dr-scratch` and re-ran the exact exploit — confirmed blocked. Phase 2
  also found and corrected a real bug in the draft itself (`security_invoker = true` on the
  replacement view silently returned zero rows to `anon`, which would have permanently emptied the
  client booking flow's practitioner picker in production). See
  [`PHASE_2_SECURITY_FIXES.md`](PHASE_2_SECURITY_FIXES.md) §1 for full before/after evidence. Not
  applied anywhere in production.

---

## P1

### P1-1 — `staff_profiles.salon_id` mass-assignment (cross-tenant staff-directory corruption)

- **Corroboration: 2 passes** — found and live-exploited by Cert v2/CP2, re-confirmed by the CP3
  write-matrix in the same pass. Not found by any earlier pass (a genuine new discovery, not a
  repeat).
- **Impact**: Medium-high (integrity, not confidentiality). `has_role()` — used by every sensitive
  RLS policy — checks `users.salon_id` (separately protected), so this does **not** grant
  cross-tenant *data* access. But `staff_profiles.salon_id` is read directly (bypassing
  `has_role()`) by `AvailabilityService._eligiblePractitionerIds`
  (`lib/core/services/availability_service.dart:390`) and by the new `v_staff_directory_public`
  view from P0-1's fix — a malicious staff account can inject itself into another tenant's public
  practitioner list and potentially get assigned as `practitioner_id` on that tenant's booking.
- **Probability**: High — trivially exploitable via one authenticated `PATCH`, no special
  privilege needed beyond being *any* staff account anywhere.
- **Criticité**: **High**.
- **OWASP/MITRE**: **API3:2023 Broken Object Property Level Authorization (Mass Assignment)**.
  CVSS 3.1 estimate from Cert v2: `AV:N/AC:L/PR:L/UI:N/S:U/C:N/I:H/A:N` ≈ **6.5 (Medium)**.
- **Preuve**: Live-exploited and reverted on `kynza-dr-scratch`: `PATCH
  /rest/v1/staff_profiles?id=eq.<id> {"salon_id":"<other salon>"}` with a QA Salon A staff JWT →
  HTTP 200, `salon_id` actually changed. Root cause: `staff_own_profile_update`'s `WITH CHECK`
  (from `supabase/migrations/20260623220000_staff_management.sql`) pins `role` to its prior value
  but never pins `salon_id`. Confirmed same policy definition present in production via read-only
  `pg_policy` check.
- **Repro**: see exact curl/PATCH sequence above (Cert v2/CP2 §CP2-1).
- **Proposed fix**:
  `supabase/migrations/20260704200000_cp2_fix_staff_profiles_salon_id_mass_assignment.sql` — pins
  `salon_id` in the `WITH CHECK` clause the same way `role` already is. No Flutter precondition
  (`StaffRepositoryImpl.updateStaff()` never sends `salon_id` in its payload — verified by code
  read, not assumption).
- **Validation method**: Apply to dr-scratch, re-run the exact exploit `PATCH` — expect it to now
  be rejected (0 rows updated / RLS violation).
- **Test plan**: (1) apply to dr-scratch, (2) re-run the exact exploit call from Cert v2/CP2,
  expect failure, (3) run existing staff-profile update tests, (4) confirm legitimate
  `updateStaff()` calls (role/display name/bio changes) still succeed.
- **Rollback plan**: Revert `WITH CHECK` clause to the pre-fix version (captured in migration).
- **Status**: **fix drafted + live-tested this pass, awaiting Mylord's explicit approval**. Phase 2
  applied to `kynza-dr-scratch` and re-ran the exact exploit PATCH — confirmed blocked (`42501` RLS
  violation). See [`PHASE_2_SECURITY_FIXES.md`](PHASE_2_SECURITY_FIXES.md) §2. Not applied anywhere
  in production.

### P1-2 — 14 backend feature migrations never deployed to production

- **Corroboration: 3 passes** — self-disclosed by Backend pass (every migration it produced is
  "staging-only" by its own admission), independently confirmed via `supabase migration list
  --linked` + a direct `information_schema.tables` check by Cert v2/CP5 (the actual discovery of
  the *scope* — Cert v1 only knew about "13 unreviewed drafts" without confirming production
  absence table-by-table), classified SAFE/REVIEW/BLOCKER by Cert v2/CP10 (`MIGRATION_REVIEW.md`).
- **Impact**: High. This is the root cause of the entire prior pass's own low Monitoring (38→20)
  and Production Readiness (33→20) scores — CMS, remote config, feature flags (enterprise layer),
  legal center, catalog/service-templates, A/B testing, business observability, audit business, and
  **all 7 Health Center dashboard RPCs** (`get_supabase_dashboard` etc.) fail an existence check in
  production. `health_center_screen.dart` degrades gracefully (`AsyncError` → `KynzaErrorState` +
  retry) rather than crashing, but every one of these features is completely non-functional for
  real users today.
- **Probability**: N/A (not a vulnerability — a deployment gap; "probability" reframed as
  "certainty this is currently broken for real users" = 100%, confirmed).
- **Criticité**: **High** (production-readiness, not security).
- **Preuve**: `supabase migration list --linked` (this session, re-confirmed): production has
  applied migrations up through `20260630150000_add_preferred_language.sql` plus a handful more —
  the following 14 are present locally, absent in production (verified via direct
  `information_schema.tables` check for representative tables: `cms_content`, `experiments`,
  `categories`, `legal_documents`, `remote_config_entries`, `service_templates` — all absent):
  | Migration | What it builds |
  |---|---|
  | `20260703120000_indexes_optimization.sql` | Performance indexes |
  | `20260703130000_catalog_schema.sql` | Service catalog/templates/variants/tags/filters |
  | `20260703140000_feature_flags_registry.sql` | Feature flags (base) |
  | `20260703150000_legal_center.sql` | Legal documents/consent/data-deletion |
  | `20260703160000_health_dashboard_views.sql` | Health dashboard views (1st wave) |
  | `20260704100000_feature_flags_enterprise.sql` | Feature flags (enterprise layer) |
  | `20260704110000_remote_config_engine.sql` | Remote config engine |
  | `20260704120000_observability_system_admin.sql` | 7 Health Center RPCs + `has_system_admin()` + `users.is_system_admin` |
  | `20260704130000_configuration_engine_coverage.sql` | Configuration engine |
  | `20260704140000_cms_enterprise.sql` | CMS content + versions |
  | `20260704150000_business_observability_schema.sql` | Business observability schema |
  | `20260704160000_ab_testing_engine.sql` | A/B testing engine |
  | `20260704170000_audit_business.sql` | Audit business |
  | `20260704180000_cp2_fk_indexes.sql` | 27 FK indexes (Cert v1's own CP2) |
- **Repro**: `supabase migration list --project-ref hhdkjfpgaklhrhfoxlhj` — compare against
  `ls supabase/migrations/`.
- **Proposed fix**: Apply all 14 in existing timestamp order (all classified **SAFE**, 0
  BLOCKER, by Cert v2/CP10 — see Phase 3 of this pass for the consolidated, re-verified plan).
- **Validation method**: Already validated together against `kynza-dr-scratch` per Cert v2/CP10.
  Re-verify with a fresh apply-to-dr-scratch-from-clean-slate if time allows in Phase 3; otherwise
  trust the existing per-migration dr-scratch validation and do a post-apply smoke test in
  production (Health Center screen load, one CMS read, one feature-flag read) immediately after
  applying.
- **Test plan**: See Phase 3 (`MIGRATION_APPLICATION_PLAN.md`) for the full dependency-ordered
  application plan and rollback-per-migration detail.
- **Rollback plan**: Per-migration, see Phase 3.
- **Status**: **fix drafted (14 migrations, all written), awaiting Mylord's explicit per-batch
  approval** — none applied by this pass.

### P1-3 — Zero backups ever protected production

- **Corroboration: 2 passes** — Cert v2/CP6 (`storage.objects` for `kynza-backups` bucket = 0 rows
  in production; no `pg_cron` job calls `create-backup`), Cert v2/CP8 restates as punch-list #7.
- **Status: ✅ CLOSED THIS PASS** — see [`PHASE_0_BACKUP_CONFIRMED.md`](PHASE_0_BACKUP_CONFIRMED.md).
  A real, restorability-proven data backup of all 55 production tables (156 rows, 280KB) was taken
  2026-07-04, stored git-ignored at `backups/prod_data_20260704T191037Z/`.
- **Residual open item** (kept as its own line so it isn't lost): **no recurring/automated backup
  exists** — this was a one-time manual export, not a schedule. Fixing this for real means either
  (a) adding a `pg_cron` job that calls `create-backup` on a cadence (needs a service-role-callable
  trigger path, since `create-backup` currently requires an authenticated owner/manager JWT — a
  cron job can't supply one without a dedicated service-role bypass), or (b) enabling Supabase's
  paid-tier PITR (`pitr_enabled: false` confirmed this pass via `supabase backups list
  --project-ref hhdkjfpgaklhrhfoxlhj` — a plan-upgrade/billing decision, not a code fix).
- **Proposed fix (residual item)**: not drafted this pass (would need a new
  service-role-authenticated variant of the backup logic, callable from `pg_cron` — a real code
  change, appropriately scoped to a future phase, not invented under time pressure here per the
  prompt's own "don't rush a fix" rule).
- **Criticité**: Medium now (one real backup exists; residual risk is *staleness* of future
  backups, not *total absence*).

### P1-4 — No real Android release keystore (Play Store blocker)

- **Corroboration: 2 passes, with a genuine contradiction between them** — Hardening pass
  (`docs/PRODUCTION_READINESS.md`) reported "Release signing ✅ resolved" (the *wiring* — conditional
  real-keystore loading in `build.gradle.kts` with debug fallback); Cert v2/CP6 & CP9 report "no
  real release keystore provisioned" as still-blocking.
- **Contradiction resolved this pass**: both are true simultaneously and don't actually conflict —
  Hardening pass fixed the *build-script wiring* (verified with a disposable test keystore, then
  deleted, per its own report), it never claimed to have generated the *real production* keystore
  (explicitly noted as "deliberately not generated in this session — one-way secret, Mylord's
  action only"). Cert v2 correctly re-confirms the real keystore still doesn't exist. **Not a
  regression, not a doc inconsistency — two different, both-accurate claims about two different
  things.** Verified this pass: `android/key.properties` does not exist in this checkout;
  `.gitignore:66` correctly excludes it (`android/key.properties`) and `*.jks`/`*.keystore`, so a
  real keystore was never meant to live in this repo. See Phase 4 for the direct resolution.
- **Impact**: Play Store submission blocker — a release build today is debug-signed, not
  submittable.
- **Status**: open — this is a Mylord action item (generate + secure the real upload keystore per
  `docs/android/RELEASE_SIGNING_PROCEDURE.md`'s documented procedure), not something Claude Code
  can or should generate unilaterally (it's explicitly described as a one-way secret across 2
  passes). Addressed in Phase 4 of this pass as "documented, reconciled, not code-fixable here."

### P1-5 — CI/CD pipeline exists but has never executed once

- **Corroboration: 3 passes** — Backend pass (`gh` unavailable, couldn't confirm), Cert v1/CP1 (same
  limitation), Cert v2/CP6 (resolved the ambiguity for real: checked via the actual public GitHub
  API — `GET api.github.com/repos/Mylord90/kynza-app/actions/runs` → `"total_count": 0"`. Repo is
  public, Actions could run, but zero runs have ever executed).
- **Impact**: Medium — no automated test/lint/build gate has ever actually run on this repo; every
  "flutter analyze: 0 issues" / "flutter test: N/N passing" claim across all 5 passes was run
  manually by whichever agent wrote that pass, never CI-enforced.
- **Status**: open. See Phase 4 — this is resolvable without new paid infrastructure (the workflow
  file already exists, the repo is already public) and is attempted directly in Phase 4 of this
  pass.

### P1-6 — Privacy Policy / Terms of Service — infrastructure built, all content still placeholder

- **Corroboration: 3 passes** — Doc pass (flagged as "the single most concrete pre-launch blocker
  found in this entire documentation pass"), Hardening pass Phase 3 (built Legal Center
  infrastructure — tables, RLS, versioning, consent tracking — but "all seeded legal document
  bodies are explicit placeholders pending real legal review... zero legal copy is asserted as
  final"), reconfirmed unresolved through Cert v1/Cert v2 (never re-flagged as fixed).
- **Impact**: Hard submission blocker for **both** Play Store and App Store — a live privacy-policy
  URL is mandatory in both consoles.
- **Status**: open — needs real legal content (a legal/business decision, not a code task) before
  either store submission can proceed. The Legal Center *mechanism* to serve/version/track
  acceptance of this content is fully built (migration `20260703150000_legal_center.sql`, part of
  P1-2's batch) — only the actual legal text is missing.

### P1-7 — iOS: untouched Flutter scaffold (App Store: full second-platform launch effort)

- **Corroboration: 2 passes** — reconfirmed as a recurring "still open" item across Doc pass,
  Hardening pass, Backend pass (iOS `Info.plist` gaps re-logged each time), formalized as an
  explicit Go/No-Go verdict by Cert v2/CP9.
- **Impact**: App Store submission is not just blocked by a checklist item — no Apple Developer
  team, no Firebase iOS config (`GoogleService-Info.plist` absent), no App Store Connect record,
  `CODE_SIGN_STYLE = Automatic` with no `DEVELOPMENT_TEAM` set. This is explicitly *not* a punch
  list — it's a full second-platform launch effort.
- **Status**: open, out of scope for a remediation pass — a scoping/resourcing decision for
  Mylord, not a bug to fix.
- **Sub-item, smaller and independently fixable**: `Info.plist` missing
  `NSCameraUsageDescription`/`NSPhotoLibraryUsageDescription`/`CFBundleURLTypes` — these specific 3
  keys are pure config, fixable without a full iOS launch effort, and are exactly the kind of "no
  production-data footprint" item Phase 4 targets.

### P1-8 — Play Store Data Safety Form not started

- **Corroboration: 2 passes** — Doc pass Part 14 (provides the real, verified data inventory:
  personal info, photos, financial records, app activity — all collected; location — not
  collected, no geolocation package exists), Cert v2/CP9 reconfirms not started.
- **Impact**: Play Store submission blocker.
- **Status**: open — this is a Play Console UI task for Mylord (not a repo artifact), the doc
  pass's data inventory should be handed to whoever fills it out.

---

## P2

Full detail kept for the ones with a live exploit or direct production impact; the rest are
tabulated compactly with source + status (still individually traceable, per exit criteria).

### P2-1 — `create_default_document_templates`: unauthenticated cross-tenant write

- **Corroboration: 1 pass** (Cert v2/CP2), fix drafted same pass at CP11.
- **OWASP**: API5:2023 Broken Function Level Authorization. CVSS ≈ 5.3 (Medium).
- **Preuve/Repro**: `POST /rest/v1/rpc/create_default_document_templates
  {"p_salon_id":"<any real salon>"}` with only the `apikey` header (no user JWT at all) → HTTP 204,
  inserts 3 default templates for that salon. Blast radius bounded by `ON CONFLICT DO NOTHING` and
  an FK constraint on `salon_id` (nonexistent salon → `23503`, not an orphan insert).
- **Proposed fix**: drafted in `supabase/migrations/20260704210000_cp11_hardening_batch.sql` — adds
  `has_role(auth.uid(), 'owner'|'manager', p_salon_id)` check, same pattern as
  `check_and_increment_promo_quota`. Same migration also revokes `get_staff_week_rank`'s dead-weight
  anon EXECUTE grant (P3-item, bundled here since it's the same file).
- **Validation/Test/Rollback**: apply to dr-scratch, re-run the exact unauthenticated repro (expect
  403/error now), `DROP FUNCTION`/recreate without check as rollback.
- **Status**: **fix drafted + live-tested this pass, awaiting approval**. Applied to dr-scratch,
  exact unauthenticated repro re-run — now `400 forbidden`. See
  [`PHASE_2_SECURITY_FIXES.md`](PHASE_2_SECURITY_FIXES.md) §3. Bundled in the same migration:
  `get_staff_week_rank`'s anon grant (P3-15) — Phase 2 found the original `REVOKE ... FROM anon`
  was a no-op (real grant came from `PUBLIC`) and corrected it to `REVOKE ... FROM PUBLIC`,
  re-verified live. Not applied anywhere in production.

### P2-2 — `calculate-commission`: cross-tenant financial disclosure

- **Corroboration: 2 passes** — flagged 🟡 "no ownership check" by Cert v1/CP3, upgraded to 🔴
  confirmed-exploitable by Cert v2/CP4 (via source-code proof, not deployed on dr-scratch to avoid
  needing to build the whole deploy path just to prove what the code already settles unambiguously).
- **OWASP**: API1:2023 BOLA. CVSS ≈ 5.3 (Medium).
- **Preuve**: `supabase/functions/calculate-commission/index.ts` calls `getAuthenticatedUser(req)`
  (any valid session, any salon, any role) then operates on whatever `booking_id` the caller
  supplies, never checking the caller's relationship to `booking.salon_id`. `staff_commissions
  .booking_id` UNIQUE bounds it to a read/disclosure risk (exact `amount_bif` + resulting
  commission of any booking, given its ID), not a write/corruption risk.
- **Proposed fix**: drafted as a code patch (CP11) — `403 forbidden` unless
  `caller.salon_id === booking.salon_id`. Risk assessed low: `BookingActionNotifier.markCompleted`
  (the only legitimate caller) always calls it for the caller's own salon.
- **Validation/Test/Rollback**: deploy patch to dr-scratch, attempt the same cross-tenant read
  (expect 403), confirm legitimate same-salon calls still work; `git revert` + redeploy as rollback.
- **Status**: **fix drafted + live-tested this pass, awaiting approval**. Reconstructed the
  pre-fix version from git history, deployed to dr-scratch, exploited it for real (learned a real
  cross-tenant booking's exact commission), cleaned up, then deployed the actual fixed code and
  re-ran the same exploit — `403 forbidden`; confirmed a legitimate same-salon call still succeeds.
  See [`PHASE_2_SECURITY_FIXES.md`](PHASE_2_SECURITY_FIXES.md) §5a. Deployed to dr-scratch only,
  not production.

### P2-3 — `run-scheduled-actions` / `schedule-reminders`: `verify_jwt` alone isn't real authorization

- **Corroboration: 2 passes** — Cert v1/CP3 noted "none (cron-only trust), by design"; Cert v2/CP4
  upgraded this to a confirmed real gap — `verify_jwt: true` is satisfied by the *public anon key*
  shipped inside the Flutter app bundle, and neither function has any additional caller check.
- **OWASP**: API2:2023 Broken Authentication.
- **Preuve**: `supabase functions list --project-ref hhdkjfpgaklhrhfoxlhj` confirms both functions
  have `verify_jwt: true` at the platform level; grep of both source files found no
  `getAuthenticatedUser`/shared-secret check.
- **Impact bound**: not invoked live against production to avoid sending real reminders/executing
  real automations against real data. Both functions have their own idempotency guards
  (`schedule-reminders` dedups via `notification_logs`; `run-scheduled-actions` is status+
  attempt-count gated) — so this is a "force off-schedule execution / mild resource-cost DoS"
  concern, not a duplicate-spam vector.
- **Proposed fix**: drafted (CP11) — `X-Cron-Secret` header check against a new `CRON_SECRET` Edge
  Function secret, plus `supabase/migrations/20260704220000_cp11_cron_secret.sql` updating the 2
  `pg_cron` job bodies to send it (sourced from Vault).
- **Precondition flagged by the draft itself**: requires setting the `CRON_SECRET` function secret
  AND storing the same value in Vault *before* applying, or reminders/automation silently stop
  firing. The draft also assumes production's `pg_cron` job names based on schedule shape — never
  directly confirmed (the query that found the 6 active jobs didn't select `jobname`).
- **Validation/Test/Rollback**: apply to dr-scratch first, confirm cron jobs still fire (their
  Vault-sourced header now includes the secret) AND that an external call without the header now
  gets rejected; `git revert` function code + re-run `cron.schedule` with the old body as rollback.
- **Status**: **fix drafted + live-tested this pass, awaiting approval**. Reconstructed pre-fix
  versions of both functions from git history, deployed to dr-scratch, confirmed both were
  callable with just the public anon key (no cron secret), then deployed the actual fixed code +
  set both real preconditions (`CRON_SECRET` function secret + matching Vault entry) and
  re-confirmed both now reject without the secret and succeed with it. **Real bug found**: the
  drafted migration's assumed `pg_cron` job names (`schedule-reminders-hourly`/
  `run-scheduled-actions-5min`) didn't match the real ones on either dr-scratch or production
  (`kynza-booking-reminders`/`kynza-run-scheduled-actions`, confirmed via direct read-only query
  against both) — corrected in the migration. Applied the corrected migration to dr-scratch and
  executed the actual `cron.job` command text end-to-end (as `pg_cron` itself would) — both jobs
  resolved their Vault secrets and got a real `200` back. See
  [`PHASE_2_SECURITY_FIXES.md`](PHASE_2_SECURITY_FIXES.md) §5b. **Medium risk item** — flagged
  explicitly for Mylord to review the precondition carefully before approving in production, since
  a botched apply silently breaks reminders (a user-facing regression, not just a security
  tightening); production already has the `project_url`/`service_role_key` Vault secrets this
  depends on (confirmed read-only), only `CRON_SECRET` would need to be added there.

### P2-4 — 2 `SECURITY DEFINER` views bypass caller permissions (`v_popular_searches`, `v_mv_daily_revenue`)

- **Corroboration: 1 pass** (Cert v1/CP2 advisor scan; routed to CP6, "still open per PHASE_11").
- **Preuve**: `supabase db advisors --type security` — 2 ERROR-level `security_definer_view`
  findings; both views execute with the view creator's permissions rather than the querying user's.
- **Proposed fix**: `ALTER VIEW ... SET (security_invoker = true)` for both, *after* confirming each
  view's current callers don't rely on the creator's elevated permissions (one may be a deliberate
  trade-off per Cert v1's own note — re-verify intent before blindly flipping).
- **Status**: open, no migration drafted yet — flagged for Phase 2/Phase 3 scoping, not rushed here
  per the "don't force a fix under time pressure" rule, since the "deliberate trade-off" note needs
  someone to actually re-derive which of the 2 views that applies to before writing the fix.

### P2-5 — Oversized payload (2MB JSON body) causes 45+ second hang, no Edge Function has a body-size limit

- **Corroboration: 1 pass** (Cert v1/CP6). Confirmed unchanged — Cert v1/CP3 separately confirmed
  0/20 functions implement any timeout.
- **Impact**: DoS-shaped finding — not confirmed whether the hang is client-upload-bound or
  server-bound; no explicit `Content-Length` check before `req.json()` on any of 20 functions.
- **Proposed fix**: not drafted — recommended pattern is a `Content-Length` pre-check + early
  rejection before parsing, applied across all 20 functions (a mechanical, repo-wide Edge Function
  hardening pass, appropriately scoped as its own follow-up, not force-fit into this remediation
  pass's time budget).
- **Status**: **Closed with Engineering Evidence (2026-07-07)** — see `docs/p2-5-rca/` (root cause:
  `Content-Length` unreliable across the Supabase gateway→Deno-isolate hop, ~70% confidence, full
  hypothesis-rejection table) and `docs/p2-5-ecr/` (fix: `readBodyGuarded()`, a shared streaming
  byte-count guard in `supabase/functions/_shared/cors.ts` depending only on bytes actually read
  from the request stream, never on the header; deployed to all 16 currently-affected Edge
  Functions). **Live-validated on production**: at every payload size this program's tooling can
  get the platform to reliably deliver (up to ~208KB, more than double `MAX_BODY_BYTES`), the fix
  is 100% deterministic across 15-30 consecutive real attempts, per function, vs. 0-20% for the
  pre-fix code tested the same session (`docs/p2-5-ecr/CP3_TESTS.md` Section H,
  `docs/p2-5-ecr/CP5_VALIDATION.md`). A known, honestly-disclosed residual: the official
  reproduction script's *default* ~300KB payload lands inside a separate, newly-discovered platform
  ceiling (**tracked as P2-28**, not part of this closure) where large-enough bodies intermittently
  never reach the isolate at all, identically on old and new code — this is why closure is scoped
  to the `Content-Length`-reliability mechanism specifically, not to "every oversized request now
  gets a fast `413`."

### P2-6 — MANAGER / SYSTEM_ADMIN role isolation never independently live-tested

- **Corroboration: 1 pass** (Cert v2/CP3, restated CP8 punch list #10). Coverage gap, not a known
  failure — the RLS *expression shape* for manager is confirmed identical in form to owner's/
  staff's, but no dedicated QA fixture for a distinct manager or system-admin account has ever
  actually exercised it live.
- **Proposed fix**: seed 2 more QA accounts (manager, system-admin) on `kynza-dr-scratch`, extend
  the existing live RLS adversarial suite to cover both roles explicitly.
- **Status**: open, test-coverage gap — addressed partially in Phase 2 of this pass if time allows
  (see Phase 2 report), otherwise carried forward.

### P2-7 — `activity_logs.ip_address`/`device_info` not populated by several Edge Functions despite columns existing

- **Corroboration: 2 passes** (Cert v2/CP1 — found via Gate 0's own exploitation-check dead end;
  Cert v2/CP5 spot-checked 2 more functions, same pattern — appears systemic, not exhaustively
  confirmed across all 20).
- **Impact**: Audit-quality gap — makes after-the-fact "was this token/RPC actually abused"
  investigations (like Gate 0's own exploitation check) much weaker than the schema implies they
  should be.
- **Status**: open, systemic, no fix drafted (would need a pass across ~20 Edge Functions' logging
  calls).

### P2-8 — `is_system_admin` has no documented grant/revoke/audit mechanism

- **Corroboration: 1 pass** — this is an audit-identified gap (surfaced by the Backend-pass research
  agent during this remediation's own reading, not flagged as a finding by any prior pass itself).
  No document across all 5 passes describes how `users.is_system_admin` actually gets granted,
  revoked, or audited — only that it's "immutable via the client API." Implies it can only be
  toggled via direct service-role DB access, with zero traceable record of who/when/why.
- **Impact**: Governance gap on a privileged, platform-wide scope (gates Health Center, CMS admin
  writes, Remote Config once migrated) — not exploitable today (the migration granting the scope
  is itself unapplied, see P1-2), but should be closed before or immediately after that migration
  ships.
- **Proposed fix**: none drafted anywhere — recommend a dedicated `grant_system_admin()`/
  `revoke_system_admin()` RPC restricted to `service_role`, writing a mandatory audit row (same
  pattern as `remote_config_audit`), rather than a raw `service_role` UPDATE with no trace.
- **Status**: open, newly flagged by this remediation pass, no fix drafted (appropriately scoped to
  land alongside or after P1-2's migration batch, not invented under this pass's time pressure).

### P2-9 — Remote Config admin functions still gate on `role === 'owner'`, not `has_system_admin()`

- **Corroboration: 4 checkpoints across 1 pass** (Backend pass CP2/CP3/CP4/CP7 — flagged at CP2 as
  interim, the fixing scope (`has_system_admin()`) was built at CP3 specifically to address it, and
  it was *still never updated* through CP4, CP5, CP6, and CP7's own final gate, which explicitly
  calls it out again as "a real, quick follow-up now that the scope exists"). Cert v1/CP1 also
  independently notes the same gap.
- **Impact**: Any of KYNZA's salon owners (not just a platform admin) can change a **platform-wide**
  remote-config default — broader access than intended, though bounded today by the fact the whole
  Remote Config engine itself is undeployed (P1-2).
- **Proposed fix**: switch both `update-remote-config` and `rollback-remote-config`'s gate from
  `role === 'owner'` to `has_system_admin()` — trivial once P1-2's migration (which creates
  `has_system_admin()`) is applied. Not yet done in any pass despite being repeatedly identified as
  "trivial."
- **Status**: open — should be bundled with P1-2's migration batch + a small Edge Function code
  change, flagged for Phase 3's application plan to sequence correctly (function code update must
  ship no earlier than the migration that creates `has_system_admin()`).

### P2-10 — Test coverage: 23.29% overall, **zero repository-layer test files exist at all**

- **Corroboration: 1 pass** (Cert v1/CP9). No dependency-injection seam or mock/fake for
  `SupabaseService` exists anywhere, so every repository directly wrapping it has 0% coverage by
  construction — 213 combined lines at 0% across `booking_repository_impl.dart`, `auth_notifier
  .dart`, `auth_repository_impl.dart`, `proxipay_repository_impl.dart`,
  `auth_supabase_datasource.dart`.
- **Proposed fix**: needs new mocking infrastructure (e.g. `mocktail`) — explicitly judged too large
  to start-and-finish safely within a single checkpoint by Cert v1; same judgment applies here.
  Addressed partially in Phase 4 of this pass if time allows (targeted at the code paths P0-1/P1-1's
  fixes touch, per the remediation prompt's Phase 4 scope), not as a general coverage sweep.
- **Status**: open, large, explicitly deferred by 2 passes now for the same good reason (avoid a
  rushed, unsafe mocking-infrastructure retrofit).

### P2-11 — `proxipay-create-session` has no unique constraint on `booking_id` (duplicate concurrent sessions)

- **Corroboration: 5 passes** — Doc pass, Hardening pass, Cert v1 (CP1 and CP3), Backend pass CP6
  (fraud-audit heuristic explicitly built to *surface*, not fix, this exact gap). **The single
  most-repeated never-fixed finding across this entire matrix.**
- **Impact**: A compromised/buggy staff session could create multiple concurrent ProxiPay payment
  sessions for the same booking; bounded only by the existing rate limit (30 req/60s per Security
  Audit V2), not an explicit one-session-per-booking guard.
- **Proposed fix**: never drafted across any of the 5 passes despite 5x corroboration — add a
  partial unique index (e.g. `UNIQUE (booking_id) WHERE status IN ('pending','processing')`) on
  `proxipay_sessions`.
- **Status**: open, no migration exists — genuinely simple, flagged here as a good Phase 2
  candidate given how many independent passes have now surfaced it without anyone actually writing
  the one-line fix.

### P2-12 — `evaluate_feature_flag()` / feature flags gate nothing in the actual app

- **Corroboration: 2 passes** (Doc pass — original finding; Cert v1 scorecard — "Feature Flags 62,
  engine unconsumed", reconfirms unchanged).
- **Status**: open — the engine works (Realtime propagation, audit trail, category/role/user
  overrides all real per Backend pass CP2), but zero screens actually call `evaluateFlag()` to gate
  behavior. Product/UX decision on which features to actually flag-gate, not a bug.

### P2-13 — `PermissionGuard` (fine-grained RBAC) built but wired into zero screens

- **Corroboration: 1 pass** (Doc pass, never revisited/fixed by any of the 4 subsequent passes).
- **Status**: open — infrastructure exists (`permission_definitions`/`permission_groups`/
  `user_permission_groups`/`user_permission_overrides`), all enforcement today is coarse role-level
  only. Needs at least one real screen wired as proof before claiming this capability is "done."

### P2-14 — `check-subscription` cron doesn't exist — lapsed paid plans never auto-revert to free

- **Corroboration: 2 passes** (Doc pass original finding, reconfirmed unchanged through Hardening/
  Backend/Cert passes — `subscription.expiring` automation trigger type seeded `wired: FALSE` for
  exactly this reason).
- **Impact**: Revenue/business-logic gap — a customer whose subscription lapses keeps Pro/Premium
  access indefinitely.
- **Status**: open, no cron/Edge Function drafted.

### P2-15 — 32 unindexed foreign keys across 24 tables (27 newly found by Cert v1/CP2, 5 pre-existing)

- **Corroboration: 2 passes** (Doc pass found 5; Cert v1/CP2 advisor scan found 27 more).
- **Proposed fix**: drafted — `supabase/migrations/20260703120000_indexes_optimization.sql` (the
  original 5) + `supabase/migrations/20260704180000_cp2_fk_indexes.sql` (the 27). Both are part of
  P1-2's 14-migration batch (already SAFE-classified).
- **Status**: fix drafted (bundled in P1-2), awaiting approval.

### P2-16 — 83 `auth_rls_initplan` warnings across 49 tables

- **Corroboration: 1 pass** (Cert v1/CP2 advisor). `auth.uid()`/`auth.role()` called directly in
  policy `USING`/`CHECK` clauses instead of `(select auth.uid())` — causes per-row re-evaluation
  (performance, not correctness).
- **Proposed fix**: deliberately **not** mechanically rewritten — risk of silently changing
  semantics across 49 tables' worth of policies without individual review.
- **Status**: open, logged, needs a dedicated per-table review pass, not a blind find-replace.

### P2-17 — 205 `multiple_permissive_policies` warnings across 23 tables

- **Corroboration: 1 pass** (Cert v1/CP2 advisor). Example: `availability_exceptions` has 2 separate
  permissive DELETE policies for `anon`.
- **Status**: open, requires per-table/action design review before merging into combined OR
  conditions (same reasoning as P2-16 — not blindly mechanized).

### P2-18 — Missing `updated_at` trigger despite the column existing (`salon_settings`, `permission_groups`, `automation_workflows`)

- **Corroboration: 1 pass** (Doc pass, explicitly called "a real correctness bug, not a design
  choice"). Never fixed by any subsequent pass.
- **Impact**: Same failure *class* the Hardening pass's own DR fault-injection test (CP7/Phase 2 of
  that pass) proved is dangerous — a silently-stale timestamp with nothing currently alerting on it.
- **Proposed fix**: not drafted — add `CREATE TRIGGER ... BEFORE UPDATE ... EXECUTE FUNCTION
  update_updated_at()` for the 3 named tables (mirrors the existing pattern used everywhere else).
- **Status**: open — genuinely simple, no reason found across 5 passes for why this was never
  fixed; good Phase 2 candidate alongside P2-11.

### P2-19 — Bank transfer details still literal `[À CONFIGURER]` placeholder

- **Corroboration: 3 passes** — original "Known gaps" item from before this remediation prompt's
  scope even began (2026-06-27 checklist), reconfirmed unfixed through every subsequent pass.
- **Impact**: Blocks any real subscription upgrade paid via bank transfer from reaching a real
  KYNZA bank account.
- **Status**: open — needs Mylord's real account details (business data, not a code fix).

### P2-20 — No alerting/threshold code exists anywhere in the codebase

- **Corroboration: 2 passes** (Cert v1/CP4 — `grep -rn "alert|threshold|Alert"` project-wide → 0
  matches; Cert v2/CP5 — reconfirms nothing to fire, since the dashboards computing threshold
  breaches are among the 14 undeployed migrations).
- **Status**: open, blocked in part on P1-2 (dashboards must exist in production before any
  alerting on them is meaningful).

### P2-21 — Certificate pinning scaffolded but permanently inert; root/jailbreak detection not implemented at all

- **Corroboration: 3 passes** (Doc pass/SECURITY_ENTERPRISE.md flagged both as ⚠️/⏳; Hardening
  pass Phase 5 built the pinning *scaffold* but left it OFF by design — no verified production
  certificate hash exists to pin without risking bricking the app on cert rotation; Cert v1/CP1 &
  CERTIFICATION_SCORECARD.md reconfirm both still unimplemented).
- **Status**: open — pinning needs a captured real cert + a renewal-tracking process (ops decision,
  not just code); root/jailbreak detection has no code or roadmap start at all.

### P2-28 — Request bodies ≳210KB have a substantial-to-near-total chance of never reaching the Edge Function isolate at all, identically on any code version

> **Renumbered 2026-07-07** (Backend Governance, Phase 1): this item was originally filed as
> `P2-22` in this document, which collided with an unrelated, already-closed `P2-22` (the
> bulk-write trigger ceiling fix, `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md:81`) in
> the canonical Master Inventory. Renumbered to `P2-28` — the next free ID in that document's own
> numbering space — to resolve the collision. See
> `docs/governance/PHASE_1_DOCUMENTARY_UNIFICATION.md`.

- **Corroboration: 1 pass** — discovered during the P2-5 Engineering Change Request
  (`docs/p2-5-ecr/CP3_TESTS.md` Sections G-H, `docs/p2-5-ecr/CP5_VALIDATION.md`) while validating
  the P2-5 streaming-guard fix, not part of any prior pass's scope.
- **Impact**: DoS-shaped — for payloads at or beyond roughly 210KB (a range that includes the
  original 2MB finding that opened P2-5, and the official reproduction script's own default
  ~300KB payload), the client-observed request intermittently — and at ~300KB, almost always —
  never receives any HTTP response at all (a genuine connection hang, not a slow success;
  confirmed with a 90s extended-wait precedent in the P2-5 RCA and repeated 10-20s timeouts here).
- **Evidence this is not an application-code bug**: proven with the *unmodified pre-ECR* code on
  **production**, given an honest, `curl`-computed, entirely accurate `Content-Length` header (no
  header trickery at all) — hung 5/5 times at 210,000 bytes. The new streaming guard (P2-5's fix)
  shows the identical behavior at the same sizes. Old code and new code are affected equally,
  which rules out either implementation as the cause — this is evidence of a platform-level
  (most plausibly the same class of Supabase gateway↔Deno-isolate propagation unreliability the
  P2-5 RCA already found for the `Content-Length` header, but here affecting the request body
  stream itself once it grows past some threshold) limitation, not a code defect.
- **Why this is a separate item from P2-5, not folded into it**: P2-5's root cause and fix were
  specifically scoped to `Content-Length` reliability; this ceiling persists even with a fully
  correct, present header, and even with a fix that never reads the header at all — a structurally
  different mechanism the P2-5 ECR's own "zero-scope-creep" constraint correctly excluded from
  that session's fix.
- **Proposed fix**: not drafted. Would need its own RCA with the same rigor as P2-5's (the P2-5 RCA
  itself suspected an unsynchronized-region/replica mechanism for the header case, folded in as
  the leading candidate rather than independently proven — the same open question likely applies
  here). No tooling available to this program can currently see inside a hung invocation from the
  outside (same ceiling the P2-5 RCA named explicitly), so root-causing this further likely needs
  Supabase dashboard Logs Explorer access or a support request, neither exercised so far.
- **Status**: open, newly discovered, not fixed, not fixable from this codebase's application code
  alone based on evidence gathered so far.

---

## P3 (tech debt / low-priority — compact form)

| ID | Title | Corroboration | Source(s) | Status |
|---|---|---|---|---|
| P3-1 | 3 real `core`↔`feature` circular dependencies (`auth_providers.dart`↔`auth_notifier.dart`; `offline_sync_providers.dart`↔3 feature providers) | 1 pass | Cert v2/CP1 (first tool-run cycle-detector ever used) | open, architecture debt |
| P3-2 | Repository-layer bypass — 14 presentation files call `SupabaseService` directly | 3 passes | Backend/CP1, Cert v1/CP1+CP8 (reconfirmed, judged too risky to fix in a cleanup checkpoint) | open, deferred |
| P3-3 | Repository/Datasource pattern only real in `auth/data`; 23 other features lack the split | 3 passes | Backend/CP1, Cert v1/CP1+CP8 | open, deferred |
| P3-4 | `app_router.dart` monolithic, 1418 lines, no `ShellRoute` | 2 passes | Doc pass, Cert v2/CP1 | open, tracked (see also memory: `project_shellroute_refactor_backlog`) |
| P3-5 | Edge Function hygiene: 0/20 timeout, ~1/20 metrics, 0/20 tracing, ~0/20 structured logging | 2 passes | Cert v1/CP3, Cert v2/CP5 | open, systemic |
| P3-6 | 8 unbounded repository stream/fetch methods (booking/notification/marketing) | 2 passes | Hardening/Phase8, Backend/CP1 | open, deferred — needs screen-by-screen filter-semantics verification |
| P3-7 | Offline outbox covers only 3 entities (`reviewCreate`/`profileUpdate`/`dataDeletionRequest`); booking/cash-payment/status-change deliberately excluded; no read-side disk cache | 2 passes | Doc pass, Hardening Phase 6, Backend/CP1 | open, partially by-design |
| P3-8 | `salon_settings`/`owner_journey_progress`/`referrals` missing `deleted_at` | 1 pass | Doc pass | open |
| P3-9 | `salons.owner_id` not a declared FK, no index | 1 pass | Doc pass | open |
| P3-10 | No formal support process / `CLIENT_SUPPORT` role at any layer | 1 pass | Doc pass, PRODUCTION_CHECKLIST Part 14 | open, product scope decision |
| P3-11 | No in-app/admin UI to create a maintenance window (SQL-only today) | 1 pass | Doc pass, PRODUCTION_CHECKLIST | open |
| P3-12 | Crash Dashboard / Performance Dashboard structurally have no queryable data source (Firebase Console-only) | 2 passes | Backend/CP3, Cert v1/CP4 | open, platform limitation |
| P3-13 | Facebook/Apple sign-in are stubs (`UnimplementedError`, "coming soon") | 1 pass | Doc pass | open, deferred to V2 by design |
| P3-14 | No Google Maps/Places/Geolocation, Firebase Analytics, or local-notifications package | 1 pass | Doc pass, API_REFERENCE_ENTERPRISE.md | open, roadmap not started |
| P3-15 | `get_staff_week_rank` has a loose, unnecessary anon EXECUTE grant (not itself exploitable — self-guarded internally) | 1 pass | Cert v2/CP2 | fix drafted, bundled in P2-1's migration (`20260704210000_cp11_hardening_batch.sql`) |
| P3-16 | `rls_enabled_no_policy` on `rate_limit_buckets` (deny-all by omission; service_role bypasses RLS anyway so low real risk) | 1 pass | Cert v1/CP2 advisor | open, needs explicit verdict (intentional deny-all vs. oversight) |
| P3-17 | `public_bucket_allows_listing` on `kynza-media` bucket | 1 pass | Cert v1/CP2 advisor | open — likely intentional (public salon photos/avatars) but never given an explicit written verdict |
| P3-18 | 2 of 4 named CMS client-consumer screens not built (`OnboardingContentScreen`, `BeautyTipsScreen`) | 1 pass | Backend/CP4 | open, small mechanical follow-up once P1-2 ships CMS to production |
| P3-19 | 50 `unused_index` advisor warnings | 1 pass | Cert v1/CP2 | not actionable pre-launch (false signal given near-zero production traffic); re-run advisor post-launch |

---

## Already resolved — verified still true, no action needed (kept for exit-criteria completeness)

| ID | Title | Resolved in | Verified how |
|---|---|---|---|
| R-1 | Android release AndroidManifest.xml "zero permissions" candidate release-blocker | Hardening/Phase 1 (`ANDROID_RELEASE_HARDENING_REPORT.md`) | Merged/release manifest already includes INTERNET/CAMERA/etc. via transitive plugin injection — the *source* manifest is empty but the real shipped one isn't. Disproven, not a regression. |
| R-2 | `leapa-webhook` missing top-level try/catch | Cert v1/CP8 | Live-verified on dr-scratch: malformed JSON + valid HMAC → 400; happy path unchanged |
| R-3 | 2 `setState`-after-`await`-without-`mounted`-check crash-risk bugs | Cert v1/CP8 | Fixed + `flutter analyze`/`flutter test` clean after |
| R-4 | SQL injection via `create-booking`'s unvalidated `practitionerId` filter | Hardening/Phase 5 | Fixed same phase |
| R-5 | `leapa-webhook` had zero rate limiting | Hardening/Phase 5 | Fixed same phase |
| R-6 | Zero backups ever taken (production data export) | **This pass, Phase 0** | See [`PHASE_0_BACKUP_CONFIRMED.md`](PHASE_0_BACKUP_CONFIRMED.md) — real backup taken, restorability proven. (Residual recurring-schedule gap tracked separately as part of P1-3.) |

---

## Cross-reference: source document → matrix ID

To satisfy the exit criteria ("every issue from every prior report appears exactly once... no
orphaned finding left in an old report but absent here"), every source document read by the 4
research passes is listed below with the matrix ID(s) it contributed to. Documents with no items
listed contributed only to already-merged IDs, confirmed-resolved items, or had no open findings.

**Doc pass**: ARCHITECTURE_GLOBAL.md→P3-1(precursor)/P2-13; WORKFLOWS.md→P2-13,P3-10,P3-13;
DATABASE_ARCHITECTURE.md→P3-8,P3-9,P2-15,P2-18; EDGE_FUNCTIONS_REFERENCE.md→P2-14,P2-11,P3-5;
CATALOG_ARCHITECTURE.md/CATALOG_EXTENSION_GUIDE.md→P1-2(catalog migration); FEATURE_FLAGS.md→P2-12;
API_REFERENCE_ENTERPRISE.md→R-1,P1-7(iOS sub-item),P3-14; ASSETS_GUIDE.md/ANIMATIONS_GUIDE.md/
DESIGN_SYSTEM.md→no open P0-P2 items (verification/measurement gaps only, folded into P3 general
"no device" root cause, not separately IDed); security/SECURITY_ENTERPRISE.md→P2-21,P3-nothing-new;
PERFORMANCE_TARGETS.md→ folded into "no device" root cause; ENTERPRISE_ARCHITECTURE_EXPANSION_REPORT.md
→P1-6.

**Harding pass**: ENTERPRISE_HARDENING_REPORT.md→P1-4(context),R-1(context); audit/PHASE_0_BASELINE.md
→ tooling-gap root cause (no Docker/Postgres, folded into notes throughout); audit/
ANDROID_RELEASE_HARDENING_REPORT.md→R-1; audit/SCHEMA_RECONCILIATION_REPORT.md→ no new open items;
LEGAL_CENTER_ARCHITECTURE.md→P1-6,P1-2(legal_center migration); OBSERVABILITY_MONITORING.md→P2-20,
P1-2(health_dashboard_views migration); DISASTER_RECOVERY_RUNBOOK.md→P1-3(context re: create-backup
scope); security/SECURITY_AUDIT_V2.md→P2-21,P2-11(reconfirmed),R-4,R-5; OFFLINE_STRATEGY.md→P3-7;
GOOGLE_MAPS_ARCHITECTURE.md→P3-14; audit/ACCESSIBILITY_PERFORMANCE_PASS.md→P3-6; TESTING_ENTERPRISE_
STRATEGY.md→P2-10(context); PRODUCTION_READINESS.md→P1-4,P1-5(context); android/RELEASE_SIGNING_
PROCEDURE.md→P1-4; security/APP_CHECK_ARCHITECTURE.md→ open but low-severity, folded into general
security-hardening backlog, not separately IDed (inert-by-design scaffold, same status as pinning).

**Backend pass**: PHASE_1_FINAL_AUDIT.md→P3-2,P3-3,P3-7,P1-5(context),P2-21(context),P1-7(context);
PHASE_3_FEATURE_FLAGS_ENGINE.md→P1-2(migration); PHASE_4_REMOTE_CONFIG.md→P2-9,P1-2(migration);
PHASE_2_OBSERVABILITY.md→P2-8,P1-2(migration); PHASE_5_HEALTH_CENTER.md→ test-coverage note folded
into P2-10; PHASE_8_CONFIGURATION_COVERAGE.md→P1-2(migration); PHASE_9_CMS_ENTERPRISE.md→P3-18,
P1-2(migration); PHASE_6_BUSINESS_OBSERVABILITY_SCHEMA.md/PHASE_7_AB_TESTING_ENGINE.md→P1-2
(migrations); PHASE_10_AUDIT_ENGINE.md→P2-11(fraud-heuristic surfaces it),P1-2(migration);
PHASE_11_BACKEND_COMPLETION_REPORT.md→P2-9(final restatement),P1-5,P2-10(coverage number).

**Cert v1**: PHASE_1_ENTERPRISE_GAP_ANALYSIS.md→P1-5,P2-21,P1-2(13-draft table),P2-9,P3-2,P3-3;
PHASE_2_DATABASE_OPTIMIZATION.md→P2-15,P2-16,P2-17,P2-4,P3-16,P3-17,P3-19; PHASE_3_EDGE_FUNCTION_
CERTIFICATION.md→P3-5,R-2(found here,fixed CP8),P2-11(reconfirmed),P2-2(flagged here, confirmed
Cert v2); PHASE_4_PERFORMANCE_OBSERVABILITY.md→P2-20,P3-12; PHASE_5_SCALABILITY.md→ folded into
general "not load-tested at real scale" note, not separately IDed (informational, no fix needed);
PHASE_6_SECURITY_OFFENSIVE.md→P0-1,P2-5; PHASE_7_DISASTER_RECOVERY.md→P2-18(same bug class),
P1-3(context); PHASE_8_CODE_QUALITY_CLEANUP.md→R-2,R-3,P3-2(reconfirmed),P3-3(reconfirmed);
PHASE_9_ENTERPRISE_TESTING_COVERAGE.md→P2-10; PHASE_11_FINAL_CERTIFICATION.md/CERTIFICATION_
SCORECARD.md→ synthesis only, all constituent items already IDed above.

**Cert v2**: GATE_0_P0_REMEDIATION.md→P0-1(fix+precondition); CP1_ARCHITECTURE_REVERIFY.md→P3-1,
P2-6(context); CP2_DEEP_SECURITY.md→P1-1,P2-1,P3-15; CP3_RLS_ADVERSARIAL_MATRIX.md→P0-1(reconfirm),
P1-1(reconfirm),P2-6; CP4_EDGE_FUNCTION_REVERIFY.md→P2-2,P2-3; CP5_OBSERVABILITY_MONITORING_GAP.md
→P1-2(discovery),P2-7,P2-20(reconfirm); CP6_DEVSECOPS_INFRA.md→P1-3,P1-4,P1-5; CP7_CODE_QUALITY_
FAST_REVERIFY.md→ no new items (confirms CP1-CP6 changes introduced no regressions); CP8_PRODUCTION_
READINESS.md→ synthesis of P0-1,P1-1,P1-2,P2-2,P2-3,P1-5,P1-3,P1-4,P3-1,P2-6,P2-7,P1-7; CP9_STORE_
GO_NO_GO.md→P1-4,P1-7,P1-8; MIGRATION_REVIEW.md→P1-2(classification),P0-1,P1-1(REVIEW-classified);
CP11_AUTOFIX_AND_VIRTUAL_PRS.md→P2-1,P2-2,P2-3(fix drafts); FINAL_ENTERPRISE_REPORT.md/SCORECARD_V2.md
→ synthesis only.

**PRODUCTION_CHECKLIST.md**: every dated update section cross-checked above; no items found in it
that aren't already covered by one of the source-pass documents that originated them (it is itself
a consolidated log, not an independent source of new findings).

**P2-5 RCA + ECR (2026-07-07, post-dates the 5 passes above)**: `docs/p2-5-rca/FINAL_RCA_REPORT.md`
→P2-5(root-caused); `docs/p2-5-ecr/CP1_DESIGN_REVIEW.md` through `CP6_DOCUMENTATION_CLOSURE.md`
→P2-5(closed with engineering evidence, see entry for scope), P2-28(discovered, opened, renumbered
from P2-22 2026-07-07 per Backend Governance Phase 1 to resolve an ID collision).
