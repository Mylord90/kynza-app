# CP4 — Disaster Recovery: Current Real State (Re-Verification)

**Enterprise Resilience & Reliability Certification (Final) — 2026-07-05**

This checkpoint does not redo the full DR audit from the Enterprise Hardening pass — it confirms
current reality given what's changed since (`docs/remediation/PHASE_0_BACKUP_CONFIRMED.md`, a real
production data backup taken 2026-07-04) and measures what that report explicitly left
unmeasured/deferred.

## 1. Backup frequency — real, not aspirational

**One-time only. No recurring job exists.** Confirmed today:
- `backups/prod_data_20260704T191037Z/` — the exact artifact from Phase 0 — is still the only
  backup on disk. No newer one has been taken since.
- No `pg_cron` job schedules a backup anywhere (grepped every migration for `cron.schedule`, no
  match tied to backups).
- `create-backup` (the only backup-shaped Edge Function that's actually deployed) is **not** a
  whole-database DR mechanism — read its source directly: it's a **per-salon, owner/manager-
  triggered, rate-limited (1/6h) self-service data export** (salon + services + staff + clients +
  90-day bookings/reviews/invoices), a customer-facing business-continuity feature, not the
  platform-level backup this checkpoint is auditing. Conflating the two would be a false positive;
  reported separately here so it isn't miscounted as DR coverage.
- Live-checked today (read-only): `supabase backups list --project-ref hhdkjfpgaklhrhfoxlhj` →
  `{"pitr_enabled": false, "backups": []}`. Supabase's own platform-level backup system is neither
  enabled nor populated on the current plan — unchanged since Phase 0's finding.

## 2. RPO — measured now, not a target

**Application data RPO right now: ~13.5 hours and rising.** The one existing backup was taken
2026-07-04T19:10:39Z; as of this checkpoint (2026-07-05, mid-morning UTC) that's the actual real
gap that would be lost in a real incident — not a design target, the literal current distance
between "now" and "last successful backup," because nothing has run since. This number grows by
one hour for every hour that passes without a second backup being taken; it will not stay at 13.5h.

**Schema RPO: 0**, unchanged from the prior pass's finding — every schema change is a versioned,
replayable migration file (76 as of this session), so schema state is always exactly reproducible
from `supabase/migrations/`, independent of any data-backup cadence.

## 3. Backup validation — done today, not a recurring system

Re-validated the existing backup artifact before trusting it for the restore rehearsal below:

```
Tables total: 55  |  OK: 55  |  Mismatch: 0  |  Errors: 0
```

Every one of the 55 per-table JSON files still parses and its row count still matches
`_manifest.json` exactly, 13.5 hours after it was taken. This is a real check run today, not an
assumption that the files are still fine — but it's a manual, ad hoc check (this session), not a
scheduled validation job. **No automated integrity check of the backup artifact exists as a
system.**

## 4. RTO — measured today, with honest caveats about what it does and doesn't prove

Ran a broader restore rehearsal than Phase 0's 3-table proof: 10 tables (82 rows total —
`permission_definitions`, `notification_templates`, `automation_actions`,
`automation_action_types`, `automation_trigger_types`, `automation_workflows`, `feature_flags`,
`subscription_plans`, `document_templates`, `app_versions`), all deliberately non-PII business-
config tables — same conservative choice Phase 0 made, still declining to load real customer PII
(`users`, `staff_profiles`, `bookings`, etc.) into the shared `kynza-dr-scratch` project without
Mylord's explicit sign-off.

```
Structure restore (CREATE TABLE ... LIKE ... INCLUDING ALL, 10 tables): 55,827 ms
Data load (82 rows, 10 tables, via REST bulk insert):                   4,604 ms
Verification (fresh SELECT count vs. backup, all 10 tables):            exact match, 0 mismatches
```

**What this does prove**: the backup format is real, current, and mechanically restorable — 10
tables this time (vs. 3 in Phase 0), covering a wider variety of column types (arrays, JSONB,
enums, defaults), all round-tripping exactly.

**What this does NOT prove, stated honestly rather than implied**:
- The 55,827ms structure-restore figure is dominated by CLI process-startup overhead (~5.5s per
  `supabase db query` invocation × 10 separate calls), not real database work — a single-
  connection batch restore would be dramatically faster. Reported as measured, not smoothed over,
  but flagged so it isn't mistaken for a real per-table DB cost.
- This rehearsal ran against `kynza-dr-scratch`, a project that **already has the full schema
  applied** (all 76 migrations). A real disaster-recovery scenario starting from a genuinely empty
  project would also need the schema replayed first — that step was **not timed in this session**
  (out of scope for a same-day re-verification; would need a freshly provisioned empty project to
  measure honestly rather than estimate).
- 82 rows is a trivial volume. The prior Final Enterprise Validation pass's CP6 scale test found a
  real ~2-minute statement-timeout wall on bulk inserts around 150k rows (a per-row trigger on
  `bookings`) — meaning this session's RTO number **does not extrapolate** to what a real-scale
  restore would cost if production data ever grows substantially. Today's production row counts
  (2 salons, 7 users, 5 bookings per Phase 0) are still pre-launch scale, so this caveat is
  currently theoretical, not urgent — but it means "RTO ≈ 1 minute" would be a false claim if
  stated without this qualifier.

## 5. Selective vs. full vs. emergency restoration capability

| Capability | Status |
|---|---|
| Selective restore (a handful of named tables into a scratch project) | **Proven twice** — Phase 0 (3 tables) and this checkpoint (10 tables), both exact-match |
| Full restore (all 55 tables, all rows, into a clean project) | **Not attempted** — same PII-handling reason both times; would need a fresh disposable project provisioned specifically for this, with Mylord's sign-off to load real customer rows anywhere outside production |
| Emergency restore (restoring *into* production itself, post-incident) | **Never attempted, never rehearsed, in either pass** — this is the actual operational gap: everything proven so far is "can this data be loaded into some other Postgres," not "can we get production itself back after losing it." Recommended as the top DR priority forward, out of scope for this same-day checkpoint to safely rehearse against the real production project |

## 6. Reconciliation against the Hardening pass's original DR claims

The original Hardening pass (`docs/certification/PHASE_7_DISASTER_RECOVERY.md`) predates Phase 0's
real backup entirely — at that time there was no production backup of any kind. Phase 0 closed
that specific gap in the interim. This checkpoint confirms: that closure is still real (files
intact, restore still works) but has not been extended into a recurring system in the ~13.5 hours
since — the "recurring backup strategy is still an open decision" framing from the remediation
report remains exactly accurate today, not stale.

## 7. Exit criteria

- [x] Backup frequency: confirmed real (one-time, zero recurrence) — not assumed.
- [x] RPO: measured as of today (~13.5h and rising for data; 0 for schema) — not a target.
- [x] RTO: measured today for a broader table set than Phase 0, with explicit, honest caveats
  about what the number does and doesn't generalize to.
- [x] Selective/full/emergency restoration capability precisely distinguished — emergency restore
  identified as the real, unaddressed gap.
- [x] Backup validation: re-run today (55/55 files valid), explicitly flagged as manual/ad hoc,
  not a system.
- [x] Zero writes to production — every production-facing command this checkpoint was read-only
  (`supabase backups list`, migration-list checks); all restore/write activity ran against
  `kynza-dr-scratch` only, cleaned up immediately after (confirmed 0 leftover tables), CLI
  re-linked back to the production ref (read-only) at the end.
