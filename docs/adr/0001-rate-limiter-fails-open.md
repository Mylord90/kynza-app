# ADR-0001: The rate limiter fails open, not closed

**Status**: Accepted (re-confirmed, Enterprise Final 100 CP2, 2026-07-05).

## Context

`check_rate_limit()` (SQL RPC) and its Edge Function wrapper `checkRateLimit()`
(`_shared/rate_limit.ts`) gate ~15 of KYNZA's Edge Functions. If the RPC call itself fails (a
transient DB hiccup, a bug in the limiter's own code), `checkRateLimit()` currently returns `true`
— the request is allowed through, not blocked. This was flagged as a security finding (P2-11,
Master Inventory) on the reasoning that "an outage/bug in the limiter itself lets requests through
rather than blocking them."

## Decision

**Keep it fail-open.** A rate limiter is the one dependency in this system where failing closed
would be worse than the risk it guards against: `checkRateLimit()` is called near the top of most
booking/payment/loyalty Edge Functions, so a transient failure in `rate_limit_buckets` (a single
small table) would, under fail-closed, take down every one of those functions — a real
availability outage traded for a temporary, bounded rate-limiting gap. This is the same tradeoff
most production rate limiters make (e.g. many API gateways document "fail open" as the deliberate
default), not an oversight specific to this codebase.

## What was actually fixed instead

The real gap wasn't the fail-open behavior — it was that the failure was silent. Fixed (CP2): the
failure path now logs via `console.error`, so a genuine limiter outage shows up in Edge Function
logs instead of disappearing without a trace.

## Consequences

- A real outage in the rate limiter degrades to "no rate limiting" for its duration, not "no
  service." Acceptable given production's near-zero current traffic and the small blast radius of
  a temporary rate-limiting gap.
- If real abuse patterns ever appear that specifically target this fail-open window, revisit this
  decision — the trigger condition for reconsidering is observed abuse during a real limiter
  outage, not a hypothetical one.
