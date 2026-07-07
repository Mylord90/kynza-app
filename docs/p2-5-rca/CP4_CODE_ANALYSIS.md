# Checkpoint 4 — Code Analysis

**Date**: 2026-07-07. **Scope**: Checkpoint 3 did not fully exonerate infrastructure (the
`Content-Length` propagation question remains open, unobservable from outside), but it also
found no infrastructure dimension it could positively blame. Per the governing prompt, this
checkpoint proceeds to check whether the application code itself could independently produce the
observed ~3-4% success rate — with a demonstration, not an intuition.

## Every file in the request path, read in full this checkpoint

`checkBodySize()` (`supabase/functions/_shared/cors.ts:36-45`):

```ts
export function checkBodySize(req: Request): Response | null {
  const len = req.headers.get("content-length");
  if (len && Number(len) > MAX_BODY_BYTES) {
    return jsonResponse({ error: "payload_too_large", max_bytes: MAX_BODY_BYTES }, 413);
  }
  return null;
}
```

- **One header read.** `Request.headers` is a standard, immutable `Headers` object per the Fetch
  API spec — `.get()` is a pure, synchronous lookup with no side effects and no dependency on
  anything outside the single `req` object passed in.
- **One numeric comparison.** No loop, no recursion, no `await`, nothing that could yield control
  mid-execution and be interleaved with another invocation.
- **No module-level state.** `MAX_BODY_BYTES` is a `const` primitive declared once at module load;
  it is never mutated, never reassigned, shared read-only across invocations by design (the same
  way every Deno module constant is) — this is safe by construction, not merely "hasn't broken
  yet."
- **No shared object, cache, counter, or connection referenced anywhere in this function.**

**Conclusion for this function in isolation: it is not possible for two concurrent (or sequential)
invocations of `checkBodySize()` to affect each other's outcome.** Given the same `req` object
(specifically, the same `Content-Length` header value), this function is 100% deterministic — it
will produce the identical result every single time, with no exception. This was verified by
direct reading, not assumed: there is no code path in this function that reads or writes anything
beyond its own single argument.

`checkRateLimit()` (`supabase/functions/_shared/rate_limit.ts:17-33`) — checked because the
governing prompt specifically names it as a hypothesis surface:

- Calls a single `admin.rpc("check_rate_limit", ...)` — the atomicity/concurrency-safety of the
  underlying Postgres function is a database-side concern, out of this checkpoint's file scope,
  but **irrelevant to P2-5 regardless**: `checkRateLimit` is called *after* `checkBodySize` in
  every one of the three traced functions. For any request `checkBodySize` correctly rejects, the
  rate limiter never executes at all. It cannot be the cause of a guard that should have already
  returned `413` two lines earlier.

`getAuthenticatedUser()` / `createServiceRoleClient()`
(`supabase/functions/_shared/supabase_admin.ts`) — same reasoning: both run strictly after
`checkBodySize` in the observed control flow of all three traced functions (confirmed by reading
`calculate-commission/index.ts:14-19`, `update-remote-config/index.ts:67-72`,
`accept-invitation/index.ts` in full this checkpoint — `handleOptions` → `checkBodySize` → nothing
else, in that fixed order, no branch that reorders it). Neither file contains a top-level mutable
variable, a `Map`/cache, or any construct that would carry state between separate invocations of
the Deno isolate. Both create a fresh Supabase client per call.

## Could business logic *downstream* explain the timeout?

Considered and rejected: if `checkBodySize` runs and returns non-null, the function returns
immediately via `return tooLarge;` — no downstream code executes at all for a rejected request.
The only way downstream logic (auth, rate limiting, `req.json()`, database calls) could be
responsible for a *hang* is if `checkBodySize` did **not** reject the request in the first place —
which loops back to the same open question Checkpoint 2/3 already identified (does the guard's
input, the header value, arrive correctly), not a new code-level defect.

## Was a race condition demonstrated? No — and here is why none could be

A race condition requires either (a) shared mutable state accessed by concurrent operations
without synchronization, or (b) a check-then-act gap where state can change between the check and
the subsequent action. Neither exists here: `checkBodySize` has no state to share, and there is no
"then-act" step — the check and the 413 response are the same synchronous return. This is
structurally different from, and much simpler than, the genuine concurrency bugs this program has
found elsewhere (e.g., the atomic-claim work in `docs/enterprise-resilience/CONCURRENCY_REPORT.md`
— those involved a real database read-then-write gap across two separate statements; this function
is a single expression with no gap to race into.

**No minimal reproduction of a code-level race, atomicity gap, or logic bug could be constructed**,
because the code does not contain the structural precondition (shared state, or a check/act gap)
that such a bug requires. This is stated as a demonstrated negative result — the demonstration
*is* the exhaustive read above, not an unverified assertion that the code "looks fine."

## Conclusion

**Checkpoint 4 finds no code-level explanation, and — more strongly than a typical negative result
— finds no code-level explanation is structurally possible given how this specific function is
written.** `checkBodySize()` is a pure function of its single input. If it produces inconsistent
results across calls, either its input is inconsistent (the `Content-Length` header value, as it
actually arrives inside the Deno isolate — unobservable per Checkpoint 2) or the function itself is
sometimes not reached/executed at all (an invocation-level platform event, not a code branch this
file controls).

## Next

Checkpoint 5 (Root Cause) — with infrastructure not fully observable-but-not-implicated by direct
evidence, and code-level causes structurally excluded, conclude with exactly one root cause and
reject every other hypothesis with the specific evidence that rules it out.
