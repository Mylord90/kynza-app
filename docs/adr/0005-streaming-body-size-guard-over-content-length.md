# ADR-0005: Enforce the body-size guard by counting bytes actually read, never by trusting `Content-Length`

**Status**: Accepted (P2-5 Engineering Change Request, 2026-07-07).

## Context

The original body-size guard, `checkBodySize()`, rejected a request as `413` only if
`req.headers.get("content-length")` was present and reported a value over `MAX_BODY_BYTES`. A
missing header was deliberately let through (documented in the code as "not a bypass"), on the
assumption that `req.json()` would have to fully buffer the body regardless, so the header check
was framed as a fast-path optimization, not the only backstop.

A dedicated RCA (`docs/p2-5-rca/`) found this assumption's failure mode live in production: the
`Content-Length` header does not reliably survive the hop from Supabase's edge gateway to the Deno
isolate that actually executes the function (~70% confidence, every alternative hypothesis —
deployment drift, code defect, race condition, rate-limiter interference — independently rejected
with evidence). When the header is lost, the guard's own designed fallback lets the request through
to `req.json()`, which buffers the full oversized body, reproducing the exact unbounded-buffering
hang the guard was built to prevent — silently killed by the platform's own `WORKER_RESOURCE_LIMIT`
with no HTTP response ever sent. Measured success rate for the guard firing correctly across 97
real attempts (two sessions): ~4%.

## Decision

Replace the header check with `readBodyGuarded()`: read `req.body` (a standard
`ReadableStream<Uint8Array>`) incrementally via `getReader()`, add each chunk's `byteLength` to a
running total, and the instant that total exceeds `MAX_BODY_BYTES`, call `reader.cancel()` and
return `413` — before the full body is ever buffered or parsed. `Content-Length` is not read at
all. Built once as a shared utility in `_shared/cors.ts`; every one of the 16 affected Edge
Functions calls this same implementation instead of a function-local check.

**Why not keep a `Content-Length` fast-path pre-check as an optimization** (the RCA's own text
suggested this was fine to keep): live testing (`docs/p2-5-ecr/CP3_TESTS.md`) found no legitimate
client can actually trigger the scenario such a pre-check would improve — a client that declares a
larger size than it sends does not produce a clean, observable request at all; it hangs at the
HTTP framing layer (the gateway waits for bytes that never arrive), before any application code
runs. Keeping the header-based branch would have reintroduced a partial `Content-Length`
dependency for a scenario that cannot legitimately occur, with no real benefit — so it was removed
entirely. The guard depends solely on bytes actually read from the stream.

## Consequences

- **The exact P2-5 mechanism is closed**: at every payload size this program's tooling can get the
  platform to reliably deliver (validated up to ~208KB, more than double `MAX_BODY_BYTES`), the new
  guard is 100% deterministic — proven side-by-side against the unmodified old code in the same
  session (0-20% success there, 100% here; `CP3_TESTS.md` Section H, `CP5_VALIDATION.md`).
- **Real, disclosed cost**: the new guard is measurably slower for a normal, well-under-limit
  request — roughly +110ms at the median (+~30%), from the extra JS-level chunk-read loop, manual
  buffer concatenation, and a separate decode+parse step versus one native `req.json()` call
  (`docs/p2-5-ecr/CP4_PERFORMANCE.md`). This is an accepted, disclosed tradeoff: a small, fixed
  latency tax on every well-behaved request in exchange for eliminating an unbounded,
  intermittently-triggered resource-exhaustion path.
- **A second, separate platform ceiling was discovered, not fixed, by this work**: payloads
  roughly ≥210KB have a substantial-to-near-total chance of never reaching the isolate at all,
  identically on old and new code, even with a fully correct, present `Content-Length`
  (`CP3_TESTS.md` Section G, proven against the *unmodified* code). This is tracked separately as
  **P2-22** (`docs/remediation/MASTER_ISSUES_MATRIX.md`) — it is not a residual piece of P2-5 (it
  persists even when the header dependency this ADR removes is entirely absent from the picture),
  and no application-level guard, streaming or otherwise, can fix a platform-level delivery gap
  that occurs before the guard's own code ever runs.
- **Any future Edge Function that accepts a JSON body must call `readBodyGuarded()`** from
  `_shared/cors.ts` rather than `req.json()` directly or a new local size check — this is the one
  place the guard is implemented, per the same anti-duplication discipline as `AtomicClaimService`.
- **If Supabase's edge infrastructure ever guarantees reliable `Content-Length` propagation** (or
  P2-22 gets independently root-caused and fixed at the platform level), this guard does not need
  to change — it was never depending on the header to begin with, so there is nothing to revert.
