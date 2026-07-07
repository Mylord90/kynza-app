# KYNZA — Change Policy

**Date**: 2026-07-07 (Backend Governance Phase 3). **Defines**: three categories of change, and
which process applies to each — directly answering "when is a full campaign justified vs. when
does a targeted session suffice vs. when is this just a normal fix."

---

## Category A — Small, targeted change

**Examples**: a single bug fix, a security patch for one already-understood issue, a dependency
version bump, a documentation correction, a one-line config change.

**Process**: standard fix — reproduce, fix, test on `kynza-dr-scratch` if it touches
backend/Supabase, request approval for anything production-bound, deploy, verify. No dedicated
report folder required; the commit message and the ticket's own row (if one was created,
`BACKEND_GOVERNANCE_GUIDE.md` §1.1) are sufficient documentation. Completable within a single
working session.

## Category B — Targeted session

**Examples**: `docs/p2-5-rca/` (a root-cause investigation into one specific, already-identified
symptom), `docs/p2-5-ecr/` (implementing and validating one specific fix), `docs/final-doc-
verification/` (a scoped documentary reconciliation), this governance effort itself.

**Trigger**: a Category A attempt reveals the issue is not actually simple — its cause is
undiagnosed, or its fix requires touching a shared mechanism used by many call sites, or (as with
this governance effort) a real, evidenced structural inconsistency was found that needs its own
dedicated, checkpoint-gated resolution.

**Process**: its own folder under `docs/`, its own checkpoint structure (however many phases the
scope actually needs — not padded to look thorough, not compressed to look fast), a closing
report, and — non-negotiably — the canonical Master Inventory updated in the same closing session
(`BACKEND_GOVERNANCE_GUIDE.md` §1.2, §6.4). A targeted session does not get to defer that update
"for later."

## Category C — Full campaign

**Examples**: Enterprise Hardening, Backend Enterprise Completion, Enterprise Final Certification
v1/v2, Enterprise Remediation, Final Enterprise Validation, Enterprise Resilience, Master Plan
Execution, Enterprise Final 100 — each spanning many subsystems, many checkpoints, days of real
work.

**Trigger — stated explicitly, since this is the question this policy exists to answer**: a new
campaign is justified only when either (a) a new, large-scope business initiative begins (a major
feature set, a new platform, a substantial architecture change) that no existing targeted-session
scope can contain, or (b) an accumulation of many small, unrelated findings genuinely needs a
single coordinated sweep rather than N independent Category B sessions — and even then, only after
confirming via `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 that the count and severity
of open items actually justifies it, not by assumption. **Given the current state (zero P0/P1
internal engineering debt, per `docs/governance/FINAL_GOVERNANCE_REPORT.md`), no Category C
campaign is currently justified** — the four remaining items are all External Dependencies
(§`MAINTENANCE_POLICY.md`), not an engineering backlog large enough to warrant one.

**Process**: per `MAINTENANCE_POLICY.md`, starting one explicitly pauses maintenance mode, with a
dated note in the canonical Master Inventory recording the pause.

---

## Migration and ADR triggers (cross-referencing `BACKEND_GOVERNANCE_GUIDE.md`, not restating)

- **Migration required**: any schema, RLS policy, function (RPC), or trigger change — see
  `BACKEND_GOVERNANCE_GUIDE.md` §2 for the full lifecycle. Applies identically regardless of
  change category (even a Category A fix that touches the schema needs a migration).
- **ADR mandatory**: per `BACKEND_GOVERNANCE_GUIDE.md` §3's criteria — non-obvious reasoning,
  costly to get wrong twice. Most Category A changes will not need one; most Category B sessions
  that change an established mechanism (as ADR-0005 did) will.

## Ticket creation/closure triggers

Per `BACKEND_GOVERNANCE_GUIDE.md` §1.1/§1.4 — a ticket is created the moment a finding is
confirmed with direct evidence (any category can create one); a ticket is closed only with direct,
re-verified evidence the fix holds where it matters. Category A changes still get a ticket if the
finding is non-trivial enough to be worth tracking (a security patch, a real bug) — a one-line
typo fix does not need one.
