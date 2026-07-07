# KYNZA — Backend Baseline: Publication Report

**Date**: 2026-07-07. **Scope**: pure Git publication of the Backend Governance & Stabilization
baseline — no code, migration, or Edge Function change. This report is the record of that
publication.

---

## What was published

| Item | Value |
|---|---|
| Tagged commit (full hash) | `a39478d74685e8927f192dda48e4ccbead393938` |
| Commit subject | `docs(governance): final governance report -- backend enters maintenance mode` |
| Tag name | `backend-baseline-v1` |
| Tag object hash | `e66fc6c029a59ff9ebf2c53183c84e64f3fbb5ef` (annotated tag) |
| Branch | `main` |
| Remote | `origin` (`https://github.com/Mylord90/kynza-app.git`) |

## Tag message (verbatim)

```
KYNZA backend baseline v1 — Backend Governance & Stabilization closure.

Backend enters maintenance mode (docs/governance/MAINTENANCE_POLICY.md) as of this commit.
Certified state: 87/87 migrations applied to production, 22 Edge Functions deployed and
versioned, 0 P0 open, 0 P1 open in Category A/B (the 4 remaining P1s are External Go-Live
Dependencies, not engineering debt). flutter analyze: 0 issues. flutter test: 411 passed,
5 skipped, 0 failed. Recurring backup and alerting cron jobs live. Documentation unified
under docs/governance/BASELINE_DOCUMENT.md as the single entry point going forward.

See CHANGELOG.md, RELEASE_NOTES.md, docs/governance/FINAL_GOVERNANCE_REPORT.md.
```

## Note on tag target — a deviation from the prepared recommendation

`docs/governance/PHASE_4_REFERENCE_BASELINE.md` (written during Phase 4, before the final
governance-closure commit existed) recommended tagging `bb6728a` (Phase 3's closing commit),
while explicitly leaving Phase 4's own commit (`78b9226`) as a stated alternative, and explicitly
framing the choice as Mylord's to make rather than deciding it unilaterally.

This publication session's instructions asked to confirm the tag points at "the last governance
closure commit" — which, in the actual history, is `a39478d` (the final governance report,
committed after Phase 4), a candidate the original recommendation didn't consider since it
predated that commit. Rather than resolve the conflict unilaterally, this was surfaced to Mylord
directly; **Mylord chose `a39478d`**. The tag was created and pushed at that commit.

## Verbatim push results

**Commits** (`git push origin main`):
```
To https://github.com/Mylord90/kynza-app.git
   159e921..a39478d  main -> main
```

**Tag** (`git push origin backend-baseline-v1`):
```
To https://github.com/Mylord90/kynza-app.git
 * [new tag]         backend-baseline-v1 -> backend-baseline-v1
```

## Verification checklist

| Step | Check | Outcome |
|---|---|---|
| 1 | Working tree clean (`git status`) | ✅ Clean, no staged/unstaged/untracked changes |
| 2 | Four+ governance closure commits present in `git log` | ✅ `89271d1` (Phase 1), `a856f64` (Phase 2), `bb6728a` (Phase 3), `78b9226` (Phase 4), `a39478d` (final governance report) |
| 3 | Current branch confirmed | ✅ `main` |
| 4 | Baseline documents exist, non-empty, governance-session content | ✅ `BASELINE_DOCUMENT.md`, `CHANGELOG.md`, `RELEASE_NOTES.md` all read and spot-checked |
| 5 | Tag `backend-baseline-v1` didn't already exist, local or remote | ✅ Confirmed absent from `git tag -l` (6 unrelated tags) and `git ls-remote --tags origin` (same 6) |
| 6 | Annotated tag created, points at correct commit | ✅ Created at `a39478d` per Mylord's explicit resolution of the commit-target ambiguity (see note above); confirmed via `git show backend-baseline-v1` |
| 7 | Commits pushed to remote (no force) | ✅ `159e921..a39478d main -> main` |
| 8 | Tag pushed to remote | ✅ `[new tag] backend-baseline-v1 -> backend-baseline-v1` |
| 9 | Tag genuinely present on remote (independently re-verified) | ✅ `git ls-remote --tags origin` shows `backend-baseline-v1` dereferencing (`^{}`) to `a39478d74685e8927f192dda48e4ccbead393938`, matching the intended commit exactly |
| 10 | This report | ✅ `docs/governance/BASELINE_PUBLICATION_REPORT.md` |

## Constraints observed

No force push. No history rewrite. No tag deleted or moved. No project file modified. No
additional commit created (this report is a new file added in a follow-up commit outside this
session's scope — see note below). One ambiguity encountered (tag target) was surfaced to Mylord
rather than resolved automatically, per instructions.

**Note**: this report file itself is new and, once committed, will require a new commit and a
follow-up push to fully land on `origin/main` — that commit/push is a separate action from the
publication this report documents, and was not performed automatically as part of this sequence
per the "never create an additional commit" constraint governing this session.

---

## Tag Target Verification (follow-up session, 2026-07-07)

Performed to prove — not assume — that `backend-baseline-v1` at `a39478d` is chronologically
later than and a superset of the two candidates named in `PHASE_4_REFERENCE_BASELINE.md`
(`bb6728a`, `78b9226`), and that it contains the full governance closure plus the final
documentary-verification corrections. Real command output below, unedited.

### 1. Chronological order (via `git merge-base` and commit timestamps)

```
$ git merge-base bb6728a a39478d
bb6728a00305568d1c3dd392fc96610cd02bcfbd

$ git merge-base 78b9226 a39478d
78b92261942fbe56d7900a3f9c5bdcc94311e332

$ git log -1 --format="%H %ai %s" bb6728a
bb6728a00305568d1c3dd392fc96610cd02bcfbd 2026-07-07 11:37:44 +0200 docs(governance): Phase 3 -- official backend freeze, policy documents, no code change

$ git log -1 --format="%H %ai %s" 78b9226
78b92261942fbe56d7900a3f9c5bdcc94311e332 2026-07-07 11:46:15 +0200 docs(governance): Phase 4 -- reference baseline, verified, none published

$ git log -1 --format="%H %ai %s" a39478d
a39478d74685e8927f192dda48e4ccbead393938 2026-07-07 11:47:18 +0200 docs(governance): final governance report -- backend enters maintenance mode
```

`git merge-base X a39478d` returning `X` itself (for both `bb6728a` and `78b9226`) proves each
is a **strict ancestor** of `a39478d`, not a diverged sibling — confirmed independently by
timestamp order: `bb6728a` (11:37:44) → `78b9226` (11:46:15) → `a39478d` (11:47:18).

**Chronologically earliest**: `bb6728a` (Phase 3). **Latest**: `a39478d` (final governance
report). `a39478d` is a direct descendant of both other candidates on the same line of history —
no branch, no rewrite.

### 2. Commits reachable from `a39478d` but not from the earlier candidates

```
$ git log --oneline bb6728a..a39478d
a39478d docs(governance): final governance report -- backend enters maintenance mode
78b9226 docs(governance): Phase 4 -- reference baseline, verified, none published

$ git log --oneline 78b9226..a39478d
a39478d docs(governance): final governance report -- backend enters maintenance mode
```

Confirms `a39478d` = `78b9226` + the final governance report commit, and `78b9226` = `bb6728a` +
Phase 4. No content is lost or bypassed between the three; `a39478d` is strictly additive over
both.

### 3. Ancestry proof — all four phase commits + the doc-verification commit

```
$ for c in 89271d1 a856f64 bb6728a 78b9226 f211d16; do
    git merge-base --is-ancestor $c a39478d && echo "$c IS an ancestor of a39478d"
  done
89271d1 IS an ancestor of a39478d
a856f64 IS an ancestor of a39478d
bb6728a IS an ancestor of a39478d
78b9226 IS an ancestor of a39478d
f211d16 IS an ancestor of a39478d
```

| Hash | Description |
|---|---|
| `89271d1` | Phase 1 — documentary unification: marks `MASTER_ISSUES_MATRIX.md` Superseded, resolves the `P2-22`→`P2-28` ID collision, declares `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` the single canonical Master Inventory, corrects its internal self-contradiction |
| `a856f64` | Phase 2 — backend governance guide, no code change |
| `bb6728a` | Phase 3 — official backend freeze, policy documents, no code change |
| `78b9226` | Phase 4 — reference baseline, verified, none published |
| `f211d16` | Final Documentary Verification — root-caused the P0/P1 status contradiction and the `P2-22` ID collision, proposed (not applied) both corrections |
| `a39478d` | Final governance report — backend enters maintenance mode (the tagged commit) |

All five are confirmed ancestors of `a39478d`. Direct diff evidence that `89271d1` performed the
renumbering and canonical declaration (not merely described it in the commit message):

```
$ git show 89271d1 | grep -n -E "P2-22|P2-28|canonical" | head -5
9:    (banner pointing to the canonical Master Inventory), and the P2-22 ID
11:    to P2-28 across both documents -- it was absent from the canonical
...
159:+### 1.2 The `P2-22` ID collision resolved — renumbered to `P2-28`
168:+| `docs/remediation/MASTER_ISSUES_MATRIX.md` | Entry heading `### P2-22` → `### P2-28`, ... |
169:+| `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` | New row added: `P2-28` ... |
```

### 4. Conclusion

**The currently-pushed tag `backend-baseline-v1` at `a39478d` is correct and complete.** It is
the chronologically latest of the three candidate commits, is a strict descendant of both
`bb6728a` and `78b9226`, and its ancestry contains all four Backend Governance & Stabilization
phase commits plus the final documentary-verification commit that identified the corrections
Phase 1 applied. No gap found; no re-tagging needed.
