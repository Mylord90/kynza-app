# P1 Verification

**Date**: 2026-07-07. **Scope**: the 7 P1 items the P2-5 ECR's Final Certification counted as
"open" (`docs/remediation/MASTER_ISSUES_MATRIX.md`'s executive summary: "P1 | 8 | 1" — 8 total,
1 already closed there = P1-3's one-time backup, leaving P1-1, P1-2, P1-4, P1-5, P1-6, P1-7, P1-8
as the 7 cited as open). Each verified directly against production or the actual repo state, not
from any report's summary alone.

---

## P1-1 — `staff_profiles.salon_id` mass-assignment

- **Matrix claim** (`MASTER_ISSUES_MATRIX.md:143-146`, 2026-07-04): "fix drafted + live-tested this
  pass, awaiting Mylord's explicit approval... Not applied anywhere in production."
- **Real status, verified live today**:
  ```
  $ supabase db query --linked "SELECT with_check FROM pg_policies WHERE tablename='staff_profiles' AND policyname='staff_own_profile_update';"
  → "(user_id = auth.uid()) AND (NOT (role IS DISTINCT FROM ...)) AND (NOT (salon_id IS DISTINCT FROM ...))"
  ```
  Both `role` **and** `salon_id` are pinned to their pre-update value in the live `WITH CHECK`
  clause — the exact fix from `20260704200000_cp2_fix_staff_profiles_salon_id_mass_assignment.sql`,
  confirmed applied (`supabase migration list --linked`, both columns populated for this
  timestamp).
- **Corroborating document**: `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md:47` —
  `Fermé (preuve)`, "Deployed to production 2026-07-06 (Go-Live Phase 2)... `pg_policies.with_check`
  re-read directly, confirms `salon_id` now pinned."
- **Conclusion**: **Closed but forgotten in the Master Inventory update** — specifically in
  `MASTER_ISSUES_MATRIX.md`, which was never touched after 2026-07-04. The other tracking document
  already has this correct.

## P1-2 — 14 (later 26/27) backend feature migrations never deployed to production

- **Matrix claim** (`MASTER_ISSUES_MATRIX.md:198-199`): "fix drafted (14 migrations, all written),
  awaiting Mylord's explicit per-batch approval — none applied by this pass."
- **Real status, verified live today**:
  ```
  $ supabase migration list --linked
  → 87 rows, every one showing both Local and Remote populated (0 unapplied)
  $ ls supabase/migrations/*.sql | wc -l
  → 87
  ```
  87 local migration files, 87 applied in production, exact match, zero gap.
- **Corroborating document**: `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md:48` —
  `Fermé (preuve)`, "All 26 remaining migrations deployed to production 2026-07-06."
- **Conclusion**: **Closed but forgotten in the Master Inventory update.** Same pattern as P1-1 —
  the count in `MASTER_ISSUES_MATRIX.md` reflects the state before the 2026-07-06 go-live batch
  and was never revised.

## P1-3's residual (recurring backup) — cited for completeness, not one of the 7 "open" items

Not one of the 7 originally counted as open (the matrix's own executive summary already counted
P1-3 as closed, referring to the one-time export). Verified anyway since it's directly relevant:
```
$ supabase db query --linked "SELECT jobname, schedule, active FROM cron.job WHERE jobname LIKE 'kynza-platform-backup';"
→ jobname: kynza-platform-backup, schedule: "0 */6 * * *", active: true
```
The residual gap the matrix flagged ("no recurring/automated backup exists... Proposed fix: not
drafted this pass") is also now closed — a cron job calling `create-platform-backup` every 6 hours
is live. `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md:49` corroborates: "fully live in
production 2026-07-06 (Go-Live Phase 3)... RPO now bounded at ≤6h going forward." **Also closed but
forgotten in `MASTER_ISSUES_MATRIX.md`.**

## P1-4 — No real Android release keystore (Play Store blocker)

- **Matrix claim** (`MASTER_ISSUES_MATRIX.md:239-242`): "open — this is a Mylord action item...
  not something Claude Code can or should generate unilaterally."
- **Real status**: genuinely still open — this is a one-way secret only Mylord can generate, and
  nothing in this codebase can close it. `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md:50`
  reclassifies it "**Reclassé External Dependency**" (Enterprise Final 100 CP11) rather than
  leaving it as undifferentiated engineering debt — a more precise characterization, not a status
  change. Not independently re-verified this session (a file-existence check for a secret this
  program has never been permitted to generate would prove nothing new); no document since
  2026-07-05 claims otherwise.
- **Conclusion**: **Genuinely still open — not a false positive, not misclassified in substance —
  but the Matrix's framing ("Mylord action item") is superseded by a later, cleaner category
  label ("External Dependency") that both documents should use consistently.**

## P1-5 — CI/CD pipeline never executed

- **Matrix claim** (`MASTER_ISSUES_MATRIX.md:253-255`): "open. See Phase 4."
- **Real status, verified live today** (direct GitHub API call, not `gh` CLI, not a report):
  ```
  $ curl https://api.github.com/repos/Mylord90/kynza-app/actions/runs?per_page=10
  → total_count: 7
    2026-07-05T05:30:53Z CI completed success
    2026-07-05T05:24:52Z CI completed success
    2026-07-05T05:07:22Z CI completed success
    2026-07-05T04:32:56Z CI completed failure
    2026-07-04T20:29:26Z CI completed failure (×3 earlier)
  ```
  7 real runs exist, the 3 most recent green — this item is unambiguously closed.
- **Corroborating document**: `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md:51,113` —
  tracked under **two different IDs** across the two documents: `P1-5` in
  `MASTER_ISSUES_MATRIX.md`, but **`R-7`** in `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`
  (its own "already resolved" bucket) — both describing the identical underlying finding.
- **Conclusion**: **Closed but forgotten in the Master Inventory update, and additionally a
  cross-document ID inconsistency** (same finding, two different IDs, in two documents that both
  claim to be authoritative issue trackers for this project).

## P1-6 — Privacy Policy / Terms of Service content

- **Matrix claim** (`MASTER_ISSUES_MATRIX.md:266-269`): "open — needs real legal content... only
  the actual legal text is missing."
- **Real status**: spot-checked directly — `supabase/migrations/20260703150000_legal_center.sql`
  seeds `legal_documents` rows; no document, commit, or code change since 2026-07-04 claims real
  legal copy was ever written (this is explicitly a business/legal decision, outside engineering's
  ability to close, and outside this session's "no new audit" mandate to re-derive from scratch).
  `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md:52` reclassifies it "**Reclassé External
  Dependency**" — consistent with the Matrix's own substance, different label.
- **Conclusion**: **Genuinely still open — not a false positive.** Framing should say "External
  Dependency," not bare "open," for consistency with the other tracking document.

## P1-7 — iOS: untouched Flutter scaffold

- **Matrix claim** (`MASTER_ISSUES_MATRIX.md:280-285`): "open, out of scope for a remediation
  pass — a scoping/resourcing decision for Mylord."
- **Real status**: no iOS-specific work appears in any commit since 2026-07-04
  (`git log --oneline -- ios/` shows no substantive commits in the relevant window); genuinely
  still open, matches `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md:53`'s "**Reclassé
  External Dependency**" (Apple Developer account).
- **Conclusion**: **Genuinely still open — not a false positive.** Same framing note as P1-6.

## P1-8 — Play Store Data Safety Form not started

- **Matrix claim** (`MASTER_ISSUES_MATRIX.md:293-294`): "open — this is a Play Console UI task for
  Mylord (not a repo artifact)."
- **Real status**: not verifiable from this repository by design (a Play Console setting, not a
  code artifact) — no evidence exists anywhere in this codebase's history that it was started.
  Matches `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md:54`'s "**Reclassé External
  Dependency**."
- **Conclusion**: **Genuinely still open — not a false positive.**

---

## Summary table

| ID | Matrix's claim | Real status (verified today) | Category |
|---|---|---|---|
| P1-1 | Open | **Closed**, live-verified | Closed, forgotten in Matrix update |
| P1-2 | Open | **Closed**, live-verified (87/87) | Closed, forgotten in Matrix update |
| P1-4 | Open | Open — External Dependency | Genuinely open, mislabeled category |
| P1-5 | Open | **Closed**, live-verified (7 real runs) | Closed, forgotten in Matrix update; also cross-doc ID mismatch (P1-5 vs. `R-7`) |
| P1-6 | Open | Open — External Dependency | Genuinely open, mislabeled category |
| P1-7 | Open | Open — External Dependency | Genuinely open, mislabeled category |
| P1-8 | Open | Open — External Dependency | Genuinely open, mislabeled category |

**Of the 7 P1 items the P2-5 ECR's Final Certification cited as open: 3 (P1-1, P1-2, P1-5) are
actually closed, live-verified today, and were only "open" because `MASTER_ISSUES_MATRIX.md` was
never updated after the 2026-07-06 go-live deployment. The remaining 4 (P1-4, P1-6, P1-7, P1-8) are
genuinely still open, but every one of them is an External Dependency (a real secret, real legal
content, an Apple Developer account, a Play Console form) — not open engineering work.**

**Proposed correction (not applied)**: update each of P1-1/P1-2/P1-5's `Status` lines in
`MASTER_ISSUES_MATRIX.md` to closed, with the citations above; correct the executive summary's
"P1 | 8 | 1" to "P1 | 8 | 4" (P1-1, P1-2, P1-3, P1-5 all closed); and either merge `P1-5`/`R-7`
into one ID across both documents or add an explicit cross-reference note so a reader of either
document knows they're the same finding.
