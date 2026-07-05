# CP3 — Genuine Remaining Engineering: Cold-Start Cache + Backup Automation + DR Rehearsal

**Date**: 2026-07-05. **Scope**: the two items the Master Plan itself confirmed were never
actually fixed (only identified) across 8 prior passes — P1-13 (cold-start-offline read cache)
and P1-3's residual (recurring backup + a real restore rehearsal). Both built and live-tested
this pass, not just designed. Nothing applied to production (`hhdkjfpgaklhrhfoxlhj`) — all
mechanism verification happened against `kynza-dr-scratch`.

---

## Part 1 — Cold-start-offline persistent cache (closes P1-13)

**Root cause, confirmed unchanged from `BUSINESS_CONTINUITY_REPORT.md`**: no read path anywhere
in the app had a disk-backed cache; every write-side offline queue existed, but a cold app start
with no network showed nothing for agenda, catalog, profile, or notification history.

**Fix applied to exactly the 4 read paths the report named**, following the codebase's own
existing convention (`CmsCache`/`FeatureFlagCache`/`RemoteConfigCache` — P1-11's already-shipped
pattern), extended to cover a subtlety those caches didn't have to deal with:

| Screen | Provider | Read shape | Fix |
|---|---|---|---|
| Agenda (client/salon/practitioner bookings) | `booking_providers.dart` (3 `StreamProvider`s) | Realtime `.stream()` | New `BookingReadCache`. `SupabaseStreamBuilder` never *errors* on a cold start offline — it just never emits — so a catch-based fallback (the CmsCache pattern) would never fire. Fixed with an `async*` generator: yields the last on-disk snapshot immediately if one exists, then forwards every live emission (mirroring each back to disk). |
| Catalog/service search | `search_providers.dart` (`searchResultsProvider`, `popularSearchesProvider`) | One-shot `Future` | New `SearchReadCache`, keyed by a query+filter signature. Genuinely throws on a network failure, so the direct `CmsCache`-style try/mirror/catch-fallback pattern applies unmodified. |
| Profile access (own profile) | `auth_providers.dart` (`currentUserProfileProvider`) | One-shot `Future` | New `ProfileReadCache`, keyed by user id. Same try/mirror/catch-fallback pattern. |
| Local history (notifications) | `notification_providers.dart` (`notificationsProvider`) | Realtime `.stream()` | New `NotificationReadCache`. Same `async*` cache-then-live pattern as bookings (same non-erroring-stream reason). |

**New Hive boxes** (`kynza_booking_cache`, `kynza_search_cache`, `kynza_profile_cache`,
`kynza_notification_cache`), opened at startup in `main.dart`. The 3 that hold real customer PII
(bookings, profile, notifications — names/phones/booking amounts) are encrypted with the same
AES cipher `SessionService`'s box already uses (`HiveEncryptionKeyService`, doc comment updated
to reflect it now protects more than one box); the search cache holds only public catalog listing
data, left unencrypted — consistent with `CmsCache`/`FeatureFlagCache` also being unencrypted for
the same reason.

**Test — the exact scenario the Master Plan asked for** (`test/unit/cold_start_offline_cache_test.dart`,
4 new tests, all passing):
- `salonBookingsProvider`: repository stubbed to return `Stream.empty()` (the real shape of "no
  network," not a thrown error) — provider's first state is the cached snapshot, proving the app
  doesn't just hang on a cold start offline.
- `searchResultsProvider`: repository stubbed to throw — falls back to the cached result set.
- `notificationsProvider`: same `Stream.empty()` treatment as bookings.
- `ProfileReadCache`: direct round-trip proof of the mechanism `currentUserProfileProvider` falls
  back to (the provider itself reads the real Supabase client, which isn't cheaply fakeable
  without new test infrastructure — flagged as a real, honest scoping limit, not silently skipped).

**Full suite**: `flutter analyze` → 0 issues. `flutter test` → 409 passed (was 405 before this
pass — count only grew), 5 skipped (the pre-existing `live`-tagged suite, unaffected).

---

## Part 2 — Recurring backup automation + real restore rehearsal (closes P1-3's residual)

### 2.1 What was built

**New migration** `20260705130000_cp3_platform_backup_automation.sql` (draft, not applied to
production):
- `platform_backup_jobs` — job-run log (status/timing/table-count/row-count/byte-size), RLS
  read-gated to `has_system_admin()`, write-only via service_role (same deny-by-omission pattern
  as `reminder_dispatch_claims`).
- `get_all_public_tables()` — enumerates every real `public` base table dynamically, so the
  export never silently goes stale the way a hardcoded table list (Phase 0's one-time manual
  export) would the next time a migration adds a table.
- `cron.schedule('kynza-platform-backup', '0 */6 * * *', ...)` — same `X-Cron-Secret`/Vault
  pattern already used by `kynza-booking-reminders`/`kynza-run-scheduled-actions`. Same
  precondition as those two, called out explicitly: `CRON_SECRET` must exist in production
  (Edge Function secret + Vault entry) before this applies.

**New Edge Function** `create-platform-backup` — cron-only (`X-Cron-Secret` gate, same as
`run-scheduled-actions`), paginates every table via the service-role PostgREST client (no
Docker/`pg_dump` needed, same constraint Phase 0 worked around), uploads one JSON file per table
plus a `_manifest.json` to the existing `kynza-backups` storage bucket under `platform/<ISO
timestamp>/`.

### 2.2 A real bug found and fixed live, this pass — not smoothed over

First live run on `kynza-dr-scratch` failed: `WORKER_RESOURCE_LIMIT`, job stuck at `running`.
Root cause, confirmed directly (`select count(*) from bookings` → **400,001**): dr-scratch still
holds the full row set from the Final Enterprise Validation scale test (`SCALABILITY_REPORT.md`,
CP6). Paginating that in a single Edge Function invocation exhausted its compute budget.

**Fix**: a per-table `MAX_ROWS_PER_TABLE` cap (20,000). A table over the cap gets its first N
rows backed up plus an honest `truncated: true` + a real `realRowCount` (a fast `count: exact,
head: true` query) in the manifest — never a silent partial export. Today's real production
volume (2 salons, 7 users, 5 bookings) is nowhere near this cap; this is the read-side analogue
of the bulk-write ceiling P2-22 already documents, not a new class of problem.

### 2.3 Live proof, not a description

- **Two independent real runs**, each producing a distinct, complete artifact:
  ```
  Run 1: job aa4a9075-... → 78 tables, 57,278 rows, 36,992,095 bytes, 26s wall time
  Run 2: job 8eb99535-... → 78 tables, 57,278 rows, 36,958,129 bytes
  ```
  `bookings` correctly recorded as `{"truncated": true, "rowCount": 20000, "realRowCount": 400001}`
  in both manifests — the cap and its honesty both proven, not asserted.
- **The `pg_cron` job is genuinely registered and active**: `select * from cron.job where jobname
  = 'kynza-platform-backup'` → `{"active": true, "schedule": "0 */6 * * *"}`.
- **Restore rehearsal** — broader than either prior rehearsal (Phase 0: 3 tables/16 rows; CP4: 10
  tables/82 rows): downloaded 6 tables from Run 2's real artifact
  (`permission_definitions`, `notification_templates`, `automation_actions`, `feature_flags`,
  `subscription_plans`, `app_versions` — same non-PII, business-config choice as both prior
  rehearsals, same reason: avoid loading real customer PII into a shared scratch project without
  Mylord's sign-off), restored into fresh `restore_verification_*` clones via
  `CREATE TABLE ... LIKE ... INCLUDING ALL` + bulk REST insert, verified exact row-count match for
  every table including a genuinely non-trivial one:
  ```
  permission_definitions:    23 / 23   ✅
  notification_templates:    12 / 12   ✅
  automation_actions:      5015 / 5015 ✅   (1.17 MB — largest table either rehearsal has tried)
  feature_flags:             32 / 32   ✅
  subscription_plans:         3 / 3    ✅
  app_versions:               2 / 2    ✅
  ```
  Total restore time (download + structure + bulk load, 6 tables, 5,087 rows): **~24 seconds**.
  Verification tables dropped immediately after; dr-scratch confirmed left clean (0 leftover
  `restore_verification_*` tables).
- **Regression check**: changing dr-scratch's `CRON_SECRET` (needed to actually exercise the
  success path, since `supabase secrets list` never reveals a settable value, only a hash) was
  also re-verified against the vault-sourced value to not break the two pre-existing cron jobs —
  `run-scheduled-actions`/`schedule-reminders` both still return `200` after the change.

### 2.4 RPO/RTO — measured, not asserted

- **Before this pass**: RPO ≈18.5h and rising unboundedly (one manual backup, 2026-07-04, no
  recurrence) — `DISASTER_RECOVERY_REPORT.md`'s own finding.
- **After this pass, on dr-scratch where the job is live**: RPO is now **bounded at ≤6 hours**
  (the cron cadence), not growing — proven by two consecutive successful automated runs.
- **In production**: still ≈unbounded until Mylord approves deploying this migration + Edge
  Function + the `CRON_SECRET` precondition (Rule 8) — this pass closes the "does the mechanism
  work" question, not the "is it live in production" question, exactly the same distinction this
  entire program draws for every other fix.
- **RTO** (this pass's 6-table/5,087-row rehearsal): ~24s including network download — consistent
  with, and now exceeding in scope, CP4's own honest caveat that this number is dominated by
  per-call overhead, not real per-row DB cost, and does not extrapolate to a genuinely full-scale
  restore (`bookings` at real scale would need the same batching CP4 flagged for the write side).

### 2.5 What this does NOT prove, stated honestly

- Full 78-table restore (not just the 6-table representative sample) was not rehearsed this pass
  — same PII-handling reason as both prior rehearsals.
- Emergency restore-into-production itself remains unrehearsed, unchanged from `DISASTER_RECOVERY_REPORT.md`'s
  own finding — still the real, top-priority DR gap, not addressed by this pass.
- The 20,000-row-per-table cap means a table that grows past it in production will get a
  correctly-flagged partial backup, not a full one, until a future pass either raises the cap with
  a multi-invocation/chunked design or Docker/PITR becomes available for a real `pg_dump`.

---

## Exit criteria check

- [x] Cold-start scenario passes a real test — 4 new tests, all passing, covering the exact
      failure mode (`Stream.empty()`/thrown error) a cold start offline actually produces.
- [x] A real automated backup run has executed at least once — **twice**, independently,
      producing two distinct complete artifacts.
- [x] A real restore rehearsal has completed with measured RPO/RTO — 6 tables, 5,087 rows, exact
      match, ~24s, broader than either prior rehearsal.
- [x] Only the two named items were built — no other infrastructure/observability topic reopened.
- [x] `flutter analyze` = 0, test count grew (405→409), no regressions.
- [x] Nothing applied to production; CLI re-linked to `hhdkjfpgaklhrhfoxlhj` and migration count
      there re-confirmed unchanged (59 applied) at the end of this session.
