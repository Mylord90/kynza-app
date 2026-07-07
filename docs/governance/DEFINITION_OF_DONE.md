# KYNZA — Definition of Done

**Date**: 2026-07-07 (Backend Governance Phase 3). **Scope**: the generic bar for any single piece
of work (a ticket, a Category A/B change) — narrower and more frequent than
`DEFINITION_OF_PRODUCTION_READY.md`, `DEFINITION_OF_SECURITY_READY.md`, or
`DEFINITION_OF_DEPLOYMENT_READY.md`, which are system-wide/release-wide gates.

---

A piece of work is **Done** when all of the following are true, with evidence for each — not
asserted:

1. **The change exists and does what it claims.** Code written, migration drafted, or document
   corrected — checked by direct read, not assumed from the plan.
2. **It's tested in the appropriate environment.** `flutter test`/`flutter analyze` for
   Flutter-side work (0 issues, per this project's held-since-baseline standard); a real
   before/after check on `kynza-dr-scratch` for anything backend-side.
3. **If it touches production-bound infrastructure**, it has explicit approval logged before
   deployment (`BACKEND_GOVERNANCE_GUIDE.md` §2.4) — not deployed speculatively "to see if it
   works."
4. **The canonical Master Inventory reflects it**, in the same session — not deferred
   (`BACKEND_GOVERNANCE_GUIDE.md` §1.4, §6.4). This is the single most commonly-skipped step in
   this project's history and the direct cause of the documentary drift Phase 1 corrected — Done
   explicitly includes this step, not just the code/fix itself.
5. **Any new ADR-worthy decision has its ADR** (`BACKEND_GOVERNANCE_GUIDE.md` §3) — not deferred to
   "later, if someone asks why."
6. **No regression** — the test suite and `flutter analyze` are re-confirmed clean after the
   change, not just before.

A piece of work that satisfies 1-3 and 6 but skips 4 or 5 is **not Done** — it is "code complete,"
a distinct and lesser status this project has always been careful to distinguish
(`Corrigé-non-déployé` in the Master Inventory's own vocabulary is exactly this state, made
explicit rather than conflated with `Fermé`).
