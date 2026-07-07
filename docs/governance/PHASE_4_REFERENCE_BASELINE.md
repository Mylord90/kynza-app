# Backend Governance — Phase 4: Reference Baseline

**Date**: 2026-07-07. **Scope**: verify the current state with real command output, then prepare
(without pushing, publishing, or touching production) a tag recommendation, versioning
convention, `CHANGELOG.md`, `RELEASE_NOTES.md`, and `BASELINE_DOCUMENT.md`.

---

## Verification — real command output, re-run at this baseline, not carried forward

| Check | Result |
|---|---|
| `flutter analyze` | **0 issues** |
| `flutter test` | **411 passed, 5 skipped, 0 failed** — "All tests passed!" |
| Migrations, production (`supabase migration list --linked`) | **87 rows, every one showing both Local and Remote populated — 0 unapplied**, matching `ls supabase/migrations/*.sql \| wc -l` → 87 exactly |
| Edge Functions, production (`supabase functions list`) | **22 total**, all `ACTIVE`; the 16 body-guarded functions all show identical `updated_at` (2026-07-07T06:05:26.593Z, the P2-5 ECR's CP5 deploy) confirming they carry the same shared-guard code, not individually drifted versions |
| ADR numbering (`ls docs/adr/*.md`) | **0001 → 0005, sequential, no gap, no collision** |
| Documentary consistency (Phase 1) | **0 broken internal links** across 135 links / 222 files (re-run after every Phase 1-4 edit) |
| Master Inventory internal consistency | Corrected this session (Phase 1) — §2 and the notice above it now agree; no further inconsistency found on re-read |

**On the historical note about migrations never matching a prior report's cited number on first
re-check**: this baseline's count (87/87, 0 unapplied) *does* match the immediately-prior source
(`docs/final-doc-verification/BODY_LIMIT_AUDIT.md` and `P0_VERIFICATION.md`, both 2026-07-07, both
also found 87/87) — the discrepancy pattern this project's history warned about was always
between reports written *days* apart during active migration work; this baseline is a same-day
re-confirmation during a documentation-only phase where no migration was applied, so agreement is
expected and confirmed, not a coincidence.

## Prepared artifacts (none applied, pushed, or published)

| Artifact | Location | Status |
|---|---|---|
| Recommended git tag | `backend-baseline-v1` at commit `bb6728a00305568d1c3dd392fc96610cd02bcfbd` (Phase 3's closing commit — the last commit before this Phase 4 verification-only work) | **Recommended, not created.** Mylord: `git tag -a backend-baseline-v1 bb6728a -m "..."` if this is confirmed. |
| Versioning convention | `docs/governance/RELEASE_POLICY.md` | Established this phase |
| `CHANGELOG.md` | Repo root | Written this phase — full campaign arc, first commit through this closure |
| `RELEASE_NOTES.md` | Repo root | Written this phase — this specific baseline's certified state |
| `BASELINE_DOCUMENT.md` | `docs/governance/` | Written this phase — the single entry point for a future session |

**Why the tag targets `bb6728a` and not this phase's own closing commit**: Phase 4 is
verification-and-preparation only — its own commit (this report, the changelog, the release notes,
the baseline document) documents the baseline, it doesn't change the code/config the baseline
describes. Tagging the last commit that actually changed anything substantive (Phase 3's policy
documents) is the more precise reference point; Mylord may equally choose to tag this phase's own
commit instead if a tag that includes the baseline documentation itself is preferred — both are
reasonable, stated here as an explicit choice rather than decided unilaterally.

## Versioning convention going forward (summary — full detail in `RELEASE_POLICY.md`)

- **Backend**: no separate version number — each migration/Edge Function deploy is its own
  release, tagged `backend-<topic>-<date>` when significant enough to want a durable reference.
- **Flutter app**: `MAJOR.MINOR.PATCH+BUILD`, existing convention, semantics now stated explicitly
  in `RELEASE_POLICY.md`.

## Next

`docs/governance/FINAL_GOVERNANCE_REPORT.md` — the closing statement: official maintenance mode,
what's now permitted vs. forbidden without a new explicitly-scoped session, and confirmation of
zero internal engineering debt with the four External Dependencies named explicitly.
