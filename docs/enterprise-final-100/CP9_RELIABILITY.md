# CP9 — Reliability

**Date**: 2026-07-05. **Scope**: confirm the circuit breaker, `AtomicClaimService`, and the
server-side atomic-claim RPC are still consistently applied everywhere a "process pending items"
pattern exists — specifically re-scanning CP1-CP8's own new code from this campaign, since new
code written during this campaign is exactly the kind of thing that could quietly reintroduce the
same concurrency-bug shape found twice before.

## Objectifs

Self-audit: did any of this campaign's own CP1-CP8 changes reintroduce the "read a pending row,
process it, no atomic claim" pattern that caused the two known concurrency bugs (Master Plan
P1-9)? Re-confirm existing protections are unchanged.

## Preuve

### Re-scan of every "pending"-status read/write pattern in the codebase, not just this campaign's own

`grep` for `status.*pending` combined with an `.update()` across every Edge Function — 2 real
hits beyond the already-known `run-scheduled-actions` (which uses `claim_pending_action_runs`,
confirmed unchanged): `claim-referral` and `validate-qr`. Both read directly, not from a
prior report:
- `claim-referral`: `.update({...}).eq("id", referral.id).eq("status", "pending").is("referred_id", null)`
  — a conditional UPDATE that re-checks `status`/`referred_id` atomically in the same statement.
  A concurrent double-claim's second UPDATE matches 0 rows (status already changed by the first),
  returning `null` — correctly rejected, not a race. Own code comment already states this
  explicitly ("a double-tap or retry can only ever consume this token once").
- `validate-qr`: same shape — `.is("used_at", null).gt("expires_at", ...)` conditional UPDATE,
  same reasoning, same existing comment already present.

**Both already correctly guarded** — this is the same atomic-claim discipline as
`claim_pending_action_runs`/`AtomicClaimService`, expressed as an inline conditional UPDATE
instead of a dedicated RPC (equally valid — the guarantee comes from the single atomic statement,
not from which mechanism expresses it). Not a gap, re-confirmed safe.

### CP1-CP8's own new code — no new instance of the vulnerable pattern

Reviewed every new/changed file from this campaign against the same question ("does this read a
shared pending/claimable resource and process it without an atomic guard?"):

| New code (this campaign) | Pattern present? | Why it's safe |
|---|---|---|
| `grant_system_admin`/`revoke_system_admin` (CP2) | No | Single-row, caller-directed UPDATE, not a "pending queue" — no concurrent-claim scenario exists |
| `MaintenanceAdminNotifier` create/delete (CP3) | No | Synchronous admin CRUD, no offline queue, no shared pending-item processing |
| `create-platform-backup` (prior session, restructured this campaign) | No | Each invocation is independent — own `platform_backup_jobs` row, own uniquely-timestamped storage prefix (`startedAt`-derived). Two concurrent runs produce two independent artifacts, not a race over shared mutable state. A same-millisecond prefix collision (astronomically unlikely) would fail one upload harmlessly (`upsert:false`), not corrupt data |
| `trg_increment_monthly_bookings` batching (CP8) | No | Aggregates via `GROUP BY` in one statement — no read-then-later-write gap; live-tested concurrently-safe by construction (single UPDATE per statement) |
| `.limit()` additions to 3 Realtime streams (CP8) | No | Read-only, no mutation, no claim semantics involved |
| `logActivity()` fix (CP6) | No | Pure insert, no read-modify-write |
| `checkBodySize`/structured logging (CP2/CP4) | No | No state mutation at all |

**No new instance found.** This campaign's own changes did not reintroduce the pattern.

### Circuit breaker and `AtomicClaimService` — re-confirmed unchanged, correctly scoped

`grep` for `DependencyCircuitBreakers.supabase.run`: still exactly 5 call sites
(`notification_service.dart`, `legal_acceptance_service.dart`, `legal_providers.dart`,
`client_profile_providers.dart`, `review_providers.dart`) — unchanged from the Enterprise
Resilience pass. `grep` for `AtomicClaimService`: still exactly 2 real consumers
(`offline_sync_coordinator.dart`, `legal_acceptance_service.dart`) plus its own definition —
unchanged. **Correctly not extended to this campaign's new admin features**: circuit breaker +
offline fallback is specifically for customer-facing mutations with a queued-retry path; the new
system-admin/maintenance-admin actions are synchronous, connectivity-required admin operations by
design, with no offline queue to protect — wiring them to the circuit breaker would be scope
creep onto a pattern that doesn't apply, not a fix.

## Statut final

No Master Inventory row maps directly to CP9 (it's a re-scan/confirmation checkpoint, not a new
finding). **Result: zero new concurrency-bug-shaped instances introduced by this campaign;
existing protections (circuit breaker, `AtomicClaimService`, `claim_pending_action_runs`, and the
2 newly-confirmed inline atomic-claim patterns in `claim-referral`/`validate-qr`) all re-confirmed
intact.**

## Documentation associée

`docs/enterprise-resilience/CONCURRENCY_REPORT.md` (original P1-9 fix), `docs/enterprise-resilience/CIRCUIT_BREAKER_REPORT.md`.

## Commit hash

See end-of-checkpoint commit.
