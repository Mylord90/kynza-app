# KYNZA — Backend Maintenance Guide

**Date**: 2026-07-07 (Backend Governance Phase 3). **Purpose**: the practical how-to for anyone
(human or AI agent) operating the backend during maintenance mode (`MAINTENANCE_POLICY.md`
defines what that mode *is*; this document is how to actually work inside it day to day).

---

## Before touching anything: read these three, in order

1. `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` — is this already a known, tracked
   item? Check §2 by keyword/table before assuming something is new.
2. `docs/governance/MAINTENANCE_POLICY.md` — is what you're about to do Category A, B, or C? Only
   A and B are in scope without first pausing maintenance mode.
3. `docs/governance/BACKEND_GOVERNANCE_GUIDE.md` — the lifecycle rules (ticket ID assignment,
   migration process, Edge Function deployment) that apply to whatever you're about to do.

## Routine checks (no fixed cadence mandated — do these when touching anything backend-adjacent)

- `supabase migration list --linked --project-ref hhdkjfpgaklhrhfoxlhj` — confirm local and
  production migration counts still match. A mismatch here is itself a Category A finding
  (someone applied something outside this process, or a draft was never synced) — investigate
  before doing anything else.
- `supabase functions list --project-ref hhdkjfpgaklhrhfoxlhj` — confirm deployed function
  versions match what's in `git log` for `supabase/functions/`. A stale deployed version relative
  to `main` is a Category A finding.
- `curl https://api.github.com/repos/Mylord90/kynza-app/actions/runs?per_page=5` — confirm CI is
  still green. A new red run is investigated before any other backend work proceeds.

## Handling an incoming report (bug, security concern, anything)

1. Reproduce it directly — against `kynza-dr-scratch` first, never production, unless the report
   is itself about production-only behavior (rare; when it happens, read-only verification first,
   per every precedent in `docs/p2-5-rca/` and `docs/final-doc-verification/`).
2. Classify severity per `BACKEND_GOVERNANCE_GUIDE.md` §5.2's table — don't skip this even for an
   apparently-obvious P0; the table exists because severity has drifted before without it.
3. Create the ticket per `BACKEND_GOVERNANCE_GUIDE.md` §1 — check the real current highest ID in
   `KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md` §2 first, always.
4. Fix, test on `kynza-dr-scratch`, request approval, deploy, re-verify live — the same sequence
   as every migration/Edge Function change (`BACKEND_GOVERNANCE_GUIDE.md` §2, §4).
5. Close the ticket in the same session, in the canonical document, with the evidence.

## When something looks bigger than a quick fix

Stop and classify it against `docs/governance/CHANGE_POLICY.md` §3 before proceeding as if it were
routine. A finding that touches multiple subsystems, or whose fix requires its own multi-step
investigation (the P2-5 RCA is the concrete precedent — what looked at first like "just redeploy
the guard" turned out to need a dedicated root-cause investigation), is Category B at minimum —
scope it explicitly, as its own session, rather than absorbing it into an unrelated maintenance
task.

## If you find a documentary inconsistency

This has happened twice already (the two-Master-Inventory divergence, and the P2-22 ID collision)
— both were real, both were found by dedicated verification sessions, not accidentally. If you
notice one:
1. Do not silently fix it in passing.
2. Verify it with direct evidence (a live query, a git log check) — not from re-reading the
   documents alone.
3. Propose the exact correction explicitly (what changes, in which file, citing the evidence) and
   apply it only after that's clear — the standing rule this entire governance effort has followed.

## Quick reference — who/what owns what

See `BACKEND_GOVERNANCE_GUIDE.md` §6.1 for the canonical-document-per-topic table. When in doubt,
that table is the answer to "where do I look."
