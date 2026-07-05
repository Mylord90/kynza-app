# CP10 — Documentation

**Date**: 2026-07-05. **Scope**: consolidate rather than duplicate — bring the master
documentation index current, write ADRs for genuinely undocumented significant decisions, correct
a stale claim found along the way. Not a new parallel report structure.

## Objectifs

Documentation consolidation, ADR establishment.

## Preuve

### `DOCUMENTATION_INDEX.md` brought current

The index hadn't been updated since Certification v2 (2026-07-04) — 5 subsequent passes
(Remediation, Final Enterprise Validation, Enterprise Resilience, the Master Plan consolidation
itself, Master Plan Execution) plus this campaign existed with no pointer from the one document
meant to be the entry point. Added one consolidated table (pass → directory → tag → what it
added) rather than fully re-detailing each — each already has its own complete report set, and
the Master Plan document itself already supersedes them for decision-making (§17 of that
document explicitly instructs exactly this: point, don't re-summarize). Added a full per-checkpoint
breakdown for this campaign specifically, since those reports didn't exist yet when the index was
last touched.

### ADRs — established for the first time in this codebase, scoped to genuinely non-obvious decisions

No `docs/adr/` existed before. Rather than retroactively documenting every historical decision
(disproportionate, and most decisions in this codebase are already explained inline via code
comments — this program's own convention throughout), wrote 4 ADRs for decisions that are
**not** obvious from reading the code alone and where getting them wrong again would cost real
time:

- **ADR-0001**: why the rate limiter fails open (a deliberate tradeoff, re-confirmed this
  campaign at CP2 — could easily be "fixed" into a worse state by someone reading only the P2-26
  finding text without the reasoning).
- **ADR-0002**: why two different atomic-claim shapes coexist (a dedicated claim RPC vs. an
  inline conditional `UPDATE`) — previously undocumented anywhere, discovered by CP9's re-scan;
  without this, a future contributor might "standardize" on one shape and lose the other's actual
  justification.
- **ADR-0003**: why aggregate-counter triggers should default to statement-level, not row-level
  (the general lesson from CP8's P2-22 fix, generalized beyond the one trigger it fixed).
- **ADR-0004**: why Realtime streams are bounded with `.limit()` rather than a server-side date
  filter (a real SDK limitation, not a design choice — a future contributor could easily "fix"
  this into a broken multi-filter chain that the SDK doesn't actually support).

### `ARCHITECTURE_GLOBAL.md` updated, not duplicated

Added a dated update note to §2.2 (Dependency graph) reflecting CP1's real fix (the 2 core↔feature
cycles) and correcting the stale "no barrel files exist" claim `CP1_ARCHITECTURE_REVERIFY.md` made
— in place, as an update to the existing authoritative document, not a new one.

## Statut final

No Master Inventory row maps directly to CP10. **Net effect**: the documentation index is current
for the first time since Cert v2; an ADR mechanism now exists with 4 real entries; one stale
architecture claim corrected in place.

## Documentation associée

`docs/DOCUMENTATION_INDEX.md`, `docs/ARCHITECTURE_GLOBAL.md`, `docs/adr/` (new).

## Commit hash

See end-of-checkpoint commit.
