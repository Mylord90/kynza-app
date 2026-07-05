# ADR-0002: Two shapes of atomic claim, used for two different problems

**Status**: Accepted (documented, Enterprise Final 100 CP9, 2026-07-05 — the pattern predates
this ADR; this records the reasoning behind an existing, previously-undocumented split).

## Context

This codebase has two genuinely different concurrency-guard shapes, both solving "don't let two
concurrent callers both act on the same row," and it isn't obvious from reading either one in
isolation why both exist rather than standardizing on one.

**Shape A — dedicated claim RPC with `FOR UPDATE SKIP LOCKED`**: `claim_pending_action_runs()`
(migration `20260705100000`), used by `run-scheduled-actions`. Claims a *batch* of rows (up to
`p_batch_size`) from a queue that a cron job polls repeatedly, where a stale claim needs to be
reclaimable after a timeout (`p_stale_after_minutes`).

**Shape B — inline conditional `UPDATE`**: `claim-referral` and `validate-qr`, e.g.
`.update({...}).eq("id", x).eq("status", "pending").is("referred_id", null)`. Claims exactly *one*
specific, caller-identified row (a referral token, a QR token), with no batch/backlog concept and
no stale-claim reclamation needed — the row is either still claimable or it isn't, forever.

## Decision

**Keep both shapes — they solve different problems, not the same problem twice.** Shape A exists
because a cron-polled queue needs batching and stale-claim recovery (a crashed worker must not
permanently orphan a row). Shape B exists because a single-row, caller-identified claim (a user
taps a specific link/scans a specific QR) has no queue to poll and no orphan-recovery need — the
conditional `UPDATE`'s atomicity guarantee (a second concurrent `UPDATE` matches 0 rows once the
first commits) is sufficient on its own, and building a claim RPC for a single row would be
unnecessary machinery.

## Consequences

- When adding a new "prevent concurrent double-processing" guard: if it's a *queue a background
  job polls repeatedly*, use Shape A's pattern (a claim RPC, batch + stale-reclaim). If it's a
  *single caller-identified resource claimed once* (a token, an invitation, a QR code), use Shape
  B's pattern (a conditional `UPDATE` with the guard condition in the `WHERE`/`.eq()` clause) — do
  not reach for a dedicated RPC where an inline conditional update already gives the same
  atomicity guarantee with less code.
- Re-confirmed live (CP9 re-scan): both `claim-referral` and `validate-qr` already use Shape B
  correctly; no new instance of either shape was needed or introduced by the Enterprise Final 100
  campaign.
