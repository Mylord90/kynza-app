# Architecture Certificate — Remediation v1

**Verdict: SUBSTANTIALLY UNCONDITIONAL, with documented non-blocking technical debt.** Unlike most
other domains, Architecture's open items are not gated by Mylord's deployment approval (Rule 8) —
they're refactor-scale code debt with no schema/production footprint, tracked honestly rather than
silently fixed under time pressure or silently ignored.

## Open items (debt, not deployment-blocked)

- **P3-1**: 3 real `core`↔`feature` circular provider dependencies, found by the first-ever
  actual import-graph/cycle-detector tool run against this codebase (Certification v2/CP1). Not
  touched this pass — a genuine refactor, correctly out of scope for a remediation pass focused on
  closing already-identified findings, not opening new architectural workstreams.
- **P3-2/P3-3**: 14 presentation files bypass the repository layer; only 1 of 24 features has a
  real datasource split. Pre-existing, reconfirmed unfixed across 3 prior passes (Backend
  Completion, Certification v1 twice). Same reasoning — real, tracked, not silently fixed here.
- **P3-4**: `app_router.dart` remains a 1418-line monolith with no `ShellRoute` — tracked tech debt
  since the Documentation Architecture pass, unchanged.

## Why this doesn't block certification

None of these three items have ever been shown to cause a runtime bug, security exposure, or user-
facing regression — they are maintainability debt. `flutter analyze` is 0 issues project-wide
(re-confirmed this pass after every code change), and the domain/data-layer purity check
Certification v2/CP1 ran (booking, loyalty, billing features) found no violations beyond the
`core`↔`feature` axis.

## Evidence

`MASTER_ISSUES_MATRIX.md` (P3-1, P3-2, P3-3, P3-4), `docs/certification-v2/CP1_ARCHITECTURE_REVERIFY.md`
(unchanged, cross-referenced not re-derived).
