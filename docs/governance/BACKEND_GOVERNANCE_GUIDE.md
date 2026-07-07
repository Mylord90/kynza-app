# KYNZA — Backend Governance Guide

**Date**: 2026-07-07 (Backend Governance Phase 2). **Purpose**: codify, as standing rules, the
practices this project has already proven work across 15+ campaigns — not invent new process.
Every rule below either already existed informally (cited from the campaign that established it)
or exists specifically to close a failure mode this project's own history demonstrated (cited to
the incident that proved it necessary). This document is itself canonical and living — update it
in place when practice changes, per its own §6.

---

## 1. Ticket Lifecycle

### 1.1 Creation

A ticket (an ID like `P0-1`, `P2-28`, `R-7`) is created the moment a finding is confirmed with
direct evidence — not from a hunch, not from a generic checklist item. Every ticket must have, at
creation: a one-line title, severity (§5.2), the evidence that proves it's real (a query result,
an exploit attempt, a failing test — never "this looks wrong"), and the source campaign/session
that found it.

### 1.2 ID assignment — the rule this document exists to establish

**The failure this rule prevents, cited by name**: the P2-5 Engineering Change Request (2026-07-07)
independently assigned a new finding the ID `P2-22` in `docs/remediation/MASTER_ISSUES_MATRIX.md`
— the next free number in *that document's* sequence — without checking whether `P2-22` was
already used in `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` (it was: an unrelated,
already-closed bulk-write-trigger fix). Two documents, two independent counters, one collision.
Found and corrected by Backend Governance Phase 1 (renumbered to `P2-28`).

**The rule, going forward**: there is exactly **one** incrementing counter per severity prefix
(`P0-`, `P1-`, `P2-`, `P3-`, `R-`), and it lives in exactly one place: **the highest number
currently used in `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 — full stop, no
exceptions.** Before assigning a new ID:
1. `grep -oE "^\| P[0-3]-[0-9]+" docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md | sort -t- -k2 -n | tail -1` (or the equivalent for `R-`) to find the current highest number for that prefix.
2. The new ID is that number + 1.
3. The new row is added to `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 **in the same
   session that discovers the finding** — never deferred to "update the tracker later." A finding
   that exists only in a campaign-folder report and not yet in §2 is not yet a ticket; it's a
   draft note.

No other document may independently assign an ID in this namespace. If a campaign folder's report
proposes an ID before the canonical document is updated (unavoidable mid-session, since the
report is usually written before this governance guide's step 3 above is executed), that ID must
be treated as provisional and reconciled into §2 before the session's closing commit — not left
for a future session to discover and fix, which is exactly how the P2-22 collision happened.

### 1.3 Priority

Set once, at creation, per §5.2's criteria — not adjusted casually. A priority change (e.g. P2→P1)
requires a one-line justification citing what new evidence changed the impact/probability
assessment, added to the ticket's row directly (see the real precedent: `P1-12`'s row in
`KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md:58` carries a `P0` in its `Priorité` column
despite its `P1-` ID — annotated "élevé par Resilience" — the existing convention for this exact
situation: the ID doesn't change, but the row states the reassessed priority with its source).

### 1.4 Closure

A ticket may be marked `Fermé (preuve)` only when direct evidence proves the fix live where it
matters (production, for anything with a production impact) — matching the standard this project
has applied since Certification v1: a before/after exploit or query re-run against the real
target, not a "should be fixed now" inference from reading the diff. `Corrigé-non-déployé` means
the fix is code-complete and tested on staging (`kynza-dr-scratch`) but not yet applied to
production — this is a distinct, real status, never silently upgraded to `Fermé`.

### 1.5 Reopening

A closed ticket may be reopened only with new, dated evidence that the original fix regressed or
was insufficient — cited exactly like a new ticket's creation evidence. A reopened ticket keeps
its original ID (never re-created under a new number) and its row gains a dated note explaining
the reopening, preserving the full history in one place rather than fragmenting it across two IDs.

### 1.6 Dependencies

Recorded in the `Dépendances` column of `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 —
"None," a specific other ticket ID, or a named precondition (e.g. P2-3's real precedent:
`CRON_SECRET` must exist as both an Edge Function secret and a Vault entry before that migration
applies). A ticket with an unmet hard dependency must not be marked ready for deployment even if
its own code is complete.

---

## 2. Migration Lifecycle

Formalizes the discipline already held without exception across this project's entire history
(re-confirmed via direct `supabase migration list --linked` checks at every single campaign
boundary, never once found violated).

1. **Creation**: a migration is drafted as a file under `supabase/migrations/`, timestamp-named,
   reviewed for its exact SQL before being considered "drafted" (not just "planned").
2. **Testing environment**: `kynza-dr-scratch` (ref `hzjmyeptytvjmzbnsmwp`) — never production —
   is the only place a migration is applied before Mylord's approval. There is no local
   Docker/Postgres stack in this project (confirmed repeatedly across campaigns); `kynza-dr-scratch`
   is the sole pre-production target.
3. **Required evidence before requesting approval**: the migration applied cleanly to
   `kynza-dr-scratch`; a real before/after check proving the change does what it claims (a query,
   an exploit re-attempt, a screen rendering real data) — not just "migration ran without error."
4. **Deployment (approval gate)**: no migration is ever applied to production
   (`hhdkjfpgaklhrhfoxlhj`) without Mylord's explicit, per-migration or per-batch approval, given
   *before* the `supabase db push`/`supabase migration up --linked` command runs — never after.
   This is the practice this project's history calls "Rule 8," held without a single violation
   across every campaign re-verified (`docs/audit/PHASE_0_BASELINE.md:151`,
   `docs/backend-completion/PHASE_11_BACKEND_COMPLETION_REPORT.md:15`, and re-confirmed at every
   later campaign boundary through the 2026-07-06 go-live phases, each of which is itself an
   explicit approval event, not a bypass of this rule).
5. **Rollback procedure**: written *before* deployment, not drafted after something breaks — the
   real precedent is `docs/go-live/PHASE_1_SECURITY_GOLIVE_REPORT.md`'s "Rollback procedure
   (written before deployment, not after)" section. A migration with no stated rollback statement
   is not ready for an approval request.
6. **Never edit an applied migration.** A correction to already-applied SQL is always a *new*,
   later-timestamped migration — never a retroactive edit to a file already run against any
   environment. (The practice this project's history calls "Rule 4.")
7. **Post-deploy verification**: re-run the same before/after check from step 3, this time against
   production itself, immediately after applying — the standard every go-live phase report in this
   project already follows.

---

## 3. ADR Process

The mechanism (`docs/adr/`) is sound as designed (`docs/adr/README.md`) — this section makes its
implicit rules explicit, not new ones.

- **When required**: a decision is ADR-worthy when its reasoning isn't derivable from reading the
  code alone, and getting it wrong again would cost real time — the exact bar `docs/adr/README.md`
  already states. Concretely: replacing one implementation strategy with a structurally different
  one for a non-obvious reason (ADR-0001, ADR-0005), a platform limitation forcing a specific
  workaround (ADR-0004), or a design choice between two valid approaches where the rejected one
  will predictably be re-proposed later (ADR-0002, ADR-0003).
- **Not ADR-worthy**: routine bug fixes, ordinary refactors, anything whose "why" is obvious from
  the code and a normal commit message.
- **Numbering**: sequential, four digits, zero-padded (`0001`, `0002`, ...), one ADR per file,
  assigned the same way ticket IDs are (§1.2) — the next unused number, checked directly
  (`ls docs/adr/*.md`) before assignment, never guessed.
- **Approval**: an ADR documents a decision already made in the same session that produced it (this
  project's convention throughout) — it is not a proposal awaiting separate sign-off, since the
  code change it describes has typically already shipped by the time the ADR is written. If an ADR
  is written for a *proposed* (not yet implemented) decision, its `Status` line must say
  `Proposed`, not `Accepted`, until the implementation lands.
- **Archival**: an ADR is never deleted when superseded — a new ADR is written, and the old one's
  `Status` line is updated to `Superseded by ADR-NNNN`, matching how every other superseded
  document in this project is treated (marked, not removed).

---

## 4. Edge Functions: Deployment, Rollback, Versioning, Validation, Monitoring

Consolidates the standing rule the P2-5 ECR established as a one-off decision (ADR-0005) into a
general policy for every current and future Edge Function.

- **Shared utilities over per-function duplication — mandatory, not a style preference.** Any
  cross-cutting concern used by more than one function (CORS, body-size guarding, rate limiting,
  auth/service-role client construction, structured logging, audit-log writing) lives in exactly
  one file under `supabase/functions/_shared/`, imported by every function that needs it. **No
  function may reimplement a shared concern locally.** This is the exact discipline `readBodyGuarded()`
  established (16 functions, one implementation, verified via `grep` that zero functions define a
  local override — `docs/final-doc-verification/BODY_LIMIT_AUDIT.md`) and the same discipline
  `AtomicClaimService`/`checkRateLimit` already followed before it.
- **Deployment**: `supabase functions deploy <name> --project-ref <ref>`, always to
  `kynza-dr-scratch` first for real testing, production only after Mylord's approval — same gate
  as migrations (§2.4). A shared-utility change (e.g. editing `_shared/cors.ts`) requires
  redeploying **every** function that imports it, not just the one under active development —
  missing this was exactly how P2-5's original fix sat live-but-untested on some functions and not
  others during the P2-5 ECR's own Checkpoint 2/3 work.
- **Rollback**: `supabase functions deploy <name>` with the pre-change code checked out (`git show
  <prior-commit>:supabase/functions/<name>/index.ts`), or `supabase functions delete <name>` for a
  function that didn't exist before the change (the real precedent for both:
  `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`'s P2-2 and P2-9 rows, which state exact
  rollback commands).
- **Versioning**: `supabase functions list --project-ref <ref>` shows `version` and `updated_at`
  per function — the authoritative record of what's actually deployed, always checked directly
  after a deploy, never assumed from the local git state alone (git and the deployed artifact can
  diverge if a deploy step is skipped or fails silently).
- **Validation before requesting production approval**: a live, evidenced before/after test against
  `kynza-dr-scratch` — the exact scenario the change addresses, not just "it deployed without
  error." For a security-relevant change, this means a real exploit attempt, both before and after.
- **Monitoring**: `activity_logs` (via the shared `logActivity()` helper — P2-7's fix, all 9
  call-sites) for business-relevant actions; `system_alerts` (via `check-system-alerts`, P1-12) for
  threshold-based operational alerting. Any new function performing a data-mutating action should
  wire into `logActivity()` from its first version, not as a later retrofit.

---

## 5. Security

### 5.1 Documentation

A vulnerability is documented the same way any ticket is created (§1.1), with these
security-specific additions, all already this project's practice:
- **OWASP/MITRE mapping** where applicable (every P0/P1/P2 security finding in
  `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` carries one — e.g. P0-1: "API3:2023 Broken
  Object Property Level Authorization... MITRE ATT&CK: T1078").
- **A working repro**: the exact `curl`/RPC call that demonstrates the issue, runnable by anyone
  with the right credentials — not a description of the issue in prose alone.
- **Blast-radius check**: what's actually exposed *right now* (e.g. P0-1's row noting "0 pending
  invitations exist in production" at time of finding) — distinguishes "a live, actively-exploited
  breach" from "a real, currently-dormant exposure," which changes urgency but never changes
  whether the underlying issue must be fixed.

### 5.2 Classification (P0-P3) — concrete criteria, since severity has drifted before

**The failure this codifies**: this project's own history shows severity assessments have shifted
between passes on the same finding (e.g. P1-12's `P0`-vs-`P1` annotation, §1.3 above) without a
single stated rubric to check against. Going forward:

| Severity | Criterion |
|---|---|
| **P0** | Live, unauthenticated (or trivially-authenticated) exploit path with account-takeover, cross-tenant data-write, or full data-exposure impact, reachable *today* in production with no precondition beyond network access. |
| **P1** | Either (a) a security/integrity gap requiring at least one non-trivial precondition to exploit (a valid-but-arbitrary auth token, a specific role), or (b) a non-security production-readiness blocker of comparable severity — a hard store-submission blocker, a data-loss risk with no mitigation (e.g. zero backups). |
| **P2** | A real, evidenced gap with limited blast radius (single-tenant, read-only, or requiring an already-privileged caller), or a reliability/DoS-shaped finding that degrades rather than breaks the system. |
| **P3** | Confirmed, real, but low-impact: architecture/maintainability debt, a missing nice-to-have hardening layer, an advisory-tool warning with no live-exploit path demonstrated. |

A severity is never assigned by directory convention or gut feel — it's assigned by checking the
finding against this table, and the row's `Impact`/`Probability`/`Criticité` cells must justify
the choice, not just state it.

### 5.3 Closure evidence standard

Unchanged from what every security-relevant closure in this project has already required, made
explicit: **a real, direct before/after exploit attempt against the environment that matters**
(production, for anything with production impact) — not a code review, not "the fix looks
correct," not a passing unit test alone (unit tests are necessary but not sufficient for a security
closure claim). This is the standard `docs/go-live/PHASE_1_SECURITY_GOLIVE_REPORT.md` and every
`backend-production-closure/CP*` report already met.

---

## 6. Documentation

### 6.1 Canonical ownership per topic (per Phase 1's ruling)

| Topic | Canonical document |
|---|---|
| Current issue/ticket status | `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 |
| What document covers what, chronologically | `docs/DOCUMENTATION_INDEX.md` |
| Architecture (compact) | `docs/ARCHITECTURE.md` |
| Architecture (expanded, diagrams) | `docs/ARCHITECTURE_GLOBAL.md` |
| Internal API/RPC surface | `docs/API_REFERENCE.md` |
| External integrations | `docs/API_REFERENCE_ENTERPRISE.md` |
| Security model (core) | `docs/SECURITY.md` |
| Security model (hardening/OWASP) | `docs/security/SECURITY_ENTERPRISE.md` |
| Architectural/engineering decisions | `docs/adr/` |
| Governance itself | `docs/governance/` (this folder) |

**Every other document in `docs/` not listed above is either a standing procedure/guide (canonical
for its own narrow topic, per Phase 1's inventory) or a historical campaign report** (evidentiary,
not to be read for "where do things stand today" — Phase 1's `PHASE_1_DOCUMENTARY_UNIFICATION.md`
has the full classification).

### 6.2 Naming/folder convention

- A new **campaign** (a multi-checkpoint audit/hardening/completion effort) gets its own folder,
  named for what it does, containing its own numbered checkpoint/phase reports and a final
  certification/closure document.
- A new **targeted session** (a single-topic RCA, ECR, or verification pass, narrower than a full
  campaign) also gets its own folder, same convention, but is expected to be shorter-lived and
  narrower in the changes it proposes.
- Both **must** update `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 directly for any
  ticket they touch (§1.2) and add an entry to `docs/DOCUMENTATION_INDEX.md`'s running "since the
  last entry" section — in the same closing commit, not deferred.

### 6.3 The rule that prevents Phase 1's root failure from recurring

**Never let two documents both claim to be "the" tracker for the same kind of information.** If a
session's own report (in its own campaign folder) needs to state a ticket's status, it must **cite**
`KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`'s row, not restate a competing status
independently. If a competing tracker is ever found to have silently diverged (as
`MASTER_ISSUES_MATRIX.md` did for the 2026-07-06 go-live deployments), the fix is exactly what
Phase 1 did: mark it Superseded with a pointer, reconcile any live findings it alone contains into
the canonical document, and never let a second copy of the same information exist as a
freestanding source of truth again.

### 6.4 Update rules

- The canonical Master Inventory (§6.1) is updated **in the same session** that changes a ticket's
  status — never batched for a later "sync" pass. This is the single most important rule in this
  document, since its violation is the entire root cause Phase 1 corrected.
- A historical document is never edited to reflect new findings — a historical document only ever
  gains a superseding pointer (Phase 1's banner pattern) if a later reader might mistake it for
  current. Its substantive content stays frozen as the record of what that pass actually found.

---

## Next

Phase 3 — the standing policy documents (Maintenance, Change, Release, Contribution, Definitions
of Done/Production-Ready/Security-Ready/Deployment-Ready) that declare the backend's operating
mode going forward, cross-referencing this guide rather than duplicating it.
