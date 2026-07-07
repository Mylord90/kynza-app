# Backend Governance — Phase 3: Official Backend Freeze

**Date**: 2026-07-07. **Purpose**: index the policy/definition documents this phase produces, and
state the one master checklist that ties them together — the objective, stated plainly per the
governing prompt: **prevent the return of undetected documentary debt**, the exact failure mode
Phase 1 found and corrected (a second, silently-diverging tracker; an ID collision).

---

## Documents produced this phase

| Document | Answers |
|---|---|
| `docs/governance/BACKEND_MAINTENANCE_GUIDE.md` | How to actually work day-to-day during maintenance mode |
| `docs/governance/BACKEND_GOVERNANCE_GUIDE.md` | (Phase 2, cross-referenced, not duplicated) — the lifecycle rules |
| `docs/governance/MAINTENANCE_POLICY.md` | When maintenance mode starts/ends, what it permits/forbids |
| `docs/governance/CHANGE_POLICY.md` | Category A/B/C — which process fits which size of change |
| `docs/governance/RELEASE_POLICY.md` | Versioning, tagging, pre-release gates |
| `docs/governance/CONTRIBUTION_POLICY.md` | How anyone (human or AI) should work in this repo |
| `docs/governance/DEFINITION_OF_DONE.md` | The generic per-change bar |
| `docs/governance/DEFINITION_OF_PRODUCTION_READY.md` | The system-wide bar |
| `docs/governance/DEFINITION_OF_SECURITY_READY.md` | The security-specific bar |
| `docs/governance/DEFINITION_OF_DEPLOYMENT_READY.md` | The pre-deploy operational checklist |

---

## The master checklist

**When is a backend change permitted?** Any Category A or B change per `CHANGE_POLICY.md`, at any
time, following `BACKEND_GOVERNANCE_GUIDE.md`'s lifecycle rules and `CONTRIBUTION_POLICY.md`'s
process. No special permission needed beyond the existing production-deploy approval gate
(`BACKEND_GOVERNANCE_GUIDE.md` §2.4).

**When is a backend change forbidden?** A Category C (campaign-scale) change during maintenance
mode, without first explicitly pausing maintenance mode (`MAINTENANCE_POLICY.md`). Any change
bypassing the approval gate before touching production. Any schema/RLS/function change made
without a migration (`BACKEND_GOVERNANCE_GUIDE.md` §2).

**When is a migration acceptable?** Any time it follows the full lifecycle in
`BACKEND_GOVERNANCE_GUIDE.md` §2 — drafted, tested on `kynza-dr-scratch`, rollback written,
approved, deployed, re-verified. Never acceptable to apply directly to production without that
sequence, regardless of how small it looks.

**When is an ADR mandatory?** Per `BACKEND_GOVERNANCE_GUIDE.md` §3 — a decision whose reasoning
isn't obvious from the code and would cost real time to re-derive wrong a second time. Not every
change needs one; most Category A changes won't.

**When does a new campaign (Category C) get justified, versus a targeted session (Category B)
suffice?** Per `CHANGE_POLICY.md` §3: a campaign only when a large new business initiative starts,
or a genuinely large accumulation of unrelated findings needs one coordinated sweep — checked
against the actual current count in the canonical Master Inventory, not assumed. **Given zero
P0/P1 engineering debt currently open, no campaign is justified today** — any new finding is a
Category A or B matter until proven otherwise by its own investigation (exactly how the P2-5 RCA
discovered its fix needed to be Category B, not assumed to be Category A from the start).

**When must a ticket be created?** The moment a finding is confirmed with direct evidence
(`BACKEND_GOVERNANCE_GUIDE.md` §1.1) — for anything non-trivial; a one-line typo doesn't need one.

**When may a ticket be closed?** Only with the evidence standard in `DEFINITION_OF_DONE.md` (§4
specifically: the canonical Master Inventory updated in the same session) and, for security
findings, `DEFINITION_OF_SECURITY_READY.md`'s four-point exploit-attempt standard.

---

## Why this prevents the specific failure already found twice

Both real documentary failures this governance effort has corrected — the silently-diverging
second "Master Inventory," and the `P2-22` ID collision — trace to the same root cause: **a
session updated one document but not the other, or assigned an ID without checking the canonical
source first.** Every policy above enforces the same single fix: **one canonical document per
topic (`BACKEND_GOVERNANCE_GUIDE.md` §6.1), updated in the same session that changes it
(§6.4), IDs assigned from that one document's own current state (§1.2), never deferred, never
duplicated.** This is not a new principle invented for this checklist — it is the one rule, stated
once, that both real failures this project has had would have been prevented by, restated here as
the standing rule going forward rather than left to be independently rediscovered by a fourth
verification session someday.

## Next

Phase 4 — Reference Baseline: verify the current state with real command output, prepare (without
publishing) a git tag recommendation, versioning convention, `CHANGELOG.md`, `RELEASE_NOTES.md`,
and the single `BASELINE_DOCUMENT.md` a future session should read first.
