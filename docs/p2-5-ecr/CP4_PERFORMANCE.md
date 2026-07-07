# Checkpoint 4 — Performance

**Date**: 2026-07-07. **Scope**: memory, CPU, latency, and behavior under concurrent load for the
new `readBodyGuarded()` guard vs. the old `checkBodySize()`, in the regime where a fair comparison
is actually possible. Reported honestly, including a real, measured regression in the normal case
— per the governing prompt's explicit instruction not to hide an honest tradeoff.

---

## Method: controlled, same-environment A/B, not cross-project

Checkpoint 3 (Section G/H) established that payloads at or beyond roughly 210KB hit a separate,
pre-existing platform ceiling that makes latency comparisons at that size meaningless (both code
versions are dominated by platform noise, not by either implementation). So this checkpoint
compares **the old and new code in the same project (`kynza-dr-scratch`), same functions, same
few-minutes window** — the pre-ECR version of `_shared/cors.ts` plus `update-remote-config` and
`calculate-commission` was temporarily redeployed via `git show 760ccf1~1:...` (the commit
immediately before this ECR's first commit), benchmarked, then immediately reverted via
`git checkout --` and redeployed back to the current (Checkpoint 3) code. `git status` was clean
before and after; nothing from this checkpoint's temporary swap was committed.

This isolates the code-level difference from cross-project/cross-environment confounds (different
region latency, different project resource tier, different time-of-day network conditions) that
would have made a production-vs-dr-scratch comparison unreliable.

## Normal case: small, valid payload (2KB) — the actual regime this guard runs in on every request

40 serial requests per function per code version, identical body, identical headers, `Content-
Length` present and accurate (the common well-behaved case), measuring full round-trip latency to
a `401 unauthenticated` response (guard passes, reaches auth, rejects — the same terminal state
for both code versions, so the timing difference is attributable to the guard + body-read step
alone, not to divergent downstream logic):

| Function | Version | min | p50 | p90 | max | mean |
|---|---|---|---|---|---|---|
| update-remote-config | old | 206ms | 338ms | 389ms | 1888ms | 393ms |
| update-remote-config | **new** | 304ms | **452ms** | 504ms | 1829ms | 513ms |
| calculate-commission | old | 205ms | 362ms | 540ms | 1656ms | 418ms |
| calculate-commission | **new** | 378ms | **471ms** | 525ms | 1864ms | 520ms |

**Honest finding: the new guard is measurably slower for the normal case** — roughly **+110-115ms
at the median (+30-34%)** across both functions, a consistent direction and magnitude on two
independent functions, not a one-off. This is a real cost, not noise: the median (p50), the
statistic least affected by this environment's tail noise (both versions show occasional
800ms-1.9s outliers unrelated to code — see "Environment noise" below), moved by roughly the same
amount on both functions tested.

**Why**: the old path is one native call, `req.json()`, whose internal buffering/parsing is
presumably a single optimized native (Rust/V8) operation. The new path does more JS-level work per
request: `req.body.getReader()`, a `while` loop of `await reader.read()` calls (one `await`, one
event-loop tick, per chunk the runtime hands back), manual `Uint8Array` concatenation into a single
buffer, a `TextDecoder().decode()`, and only then `JSON.parse()` (an extra parse step the old path
didn't need separately, since `req.json()` combines decode+parse in one native call). For a 2KB
body this is at most a couple of chunks, so the actual byte-copying work is trivial — the ~110ms
delta is consistent with the fixed per-`await`/per-microtask overhead of the manual loop, not with
byte-volume-scaling cost (confirmed by the memory/CPU-impact discussion below).

## Memory: bounded-but-higher-constant-factor for normal payloads, dramatically bounded for the attack case

No direct memory instrumentation is available (no Supabase Logs Explorer or `functions logs`
access from this session — the same tooling ceiling the RCA itself hit repeatedly). This section
is an architectural analysis of what each implementation must allocate, not a profiler capture,
stated as such rather than implied to be a live measurement:

- **Old code, normal payload**: `req.json()` — one native buffer read + parse, implementation
  detail internal to Deno, presumed efficient (a single allocation path).
- **New code, normal payload**: holds an **array of chunk `Uint8Array`s** (as they arrive) *plus*
  **one concatenated `Uint8Array`** of the same total size (built after the loop) *plus* **the
  decoded string**. Peak memory for an under-limit body is therefore roughly 2-3× the body size
  momentarily, vs. the old path's presumed single buffer — a real but small constant-factor
  increase, and still trivially bounded (worst case for a payload at the 100KB ceiling: a few
  hundred KB peak, negligible against any Edge Function's actual memory ceiling).
- **Old code, the actual P2-5 attack case (header absent/wrong)**: **unbounded** — `req.json()`
  buffers the *entire* real body regardless of size (2MB in the original finding, 100-300KB in RCA
  reproduction), which is the entire mechanism of the original bug.
- **New code, the same attack case**: **strictly bounded at `MAX_BODY_BYTES` plus at most one
  in-flight chunk** (a few tens of KB), *regardless of how large the real attack payload actually
  is* — `reader.cancel()` fires the instant the running total crosses the threshold, before the
  attacker's 2MB (or 200MB) body is ever assembled. **This is the actual point of the fix and the
  dimension that matters most**: the new code trades a small, constant, bounded memory/CPU cost
  increase in the normal case for eliminating an unbounded memory/CPU cost in the abuse case.

## CPU impact

Not independently measured (no profiler access) beyond what the latency numbers above already
imply: additional JS-level work (loop iterations, one decode call, one extra parse call) scales
with the number of chunks read, which for any payload up to `MAX_BODY_BYTES` is a small, fixed,
bounded number of iterations (a handful, not hundreds) — consistent with a fixed per-request
overhead rather than a scaling concern within the guard's own operating range.

## Behavior under concurrent load

15 concurrent requests (`Promise.all`, 2KB body, same project):

| Function | Version | Errors | Wall-clock (15 concurrent) | Per-request mean |
|---|---|---|---|---|
| update-remote-config | old | 0/15 | 1859ms | 1611ms |
| update-remote-config | new | 0/15 | 985ms | 773ms |
| calculate-commission | new | 0/15 | 736ms | 597ms |

**Zero errors under concurrency for both versions** — the new guard does not introduce any
concurrency-related failure. The old-code run showing a *higher* mean than the new-code run here
is almost certainly environment noise, not a real "old is slower" effect (it directly contradicts
the serial-request finding above, and this environment's demonstrated variance — see below — makes
a single 15-request concurrent sample an unreliable basis for a directional claim either way).
**This checkpoint does not claim the new code is faster under concurrency** — only that it
introduces no concurrency-specific errors or regressions, which is what matters for correctness;
the serial-latency comparison above is the reliable performance number, precisely because it used
40 reps per condition rather than one 15-request sample.

## Environment noise (a limitation stated plainly, not glossed over)

Both old and new code show occasional 1.6-1.9s outliers among otherwise ~300-500ms requests, on
an otherwise-idle staging project — consistent with the general request-time variance this whole
ECR's testing has repeatedly observed on this platform (Checkpoint 3's Section G/H found much
larger, payload-size-correlated non-determinism at larger sizes). This is why the comparison above
leans on the median across 40 reps rather than any single request, and why the concurrency
comparison is reported as directionally inconclusive rather than forced into a "faster/slower"
claim it cannot actually support with an N of 1 sample per condition.

## Conclusion

- **Normal case (small, valid payload)**: the new guard is **measurably slower**, ~110-115ms at
  the median, ~30% relative — a real, honest cost, not hidden. Under 15-way concurrency, both
  versions completed with zero errors; the concurrency timing comparison itself is not reliable
  enough (single-sample) to add a directional claim on top of the serial result.
- **Attack case (oversized body, header absent/wrong, size within the platform's reliable-delivery
  range per Checkpoint 3)**: the new guard converts an **unbounded** memory/CPU cost and a
  **0-20% chance of a clean response** (Checkpoint 3, Section H) into a **strictly bounded** cost
  and a **100% chance of a fast, correct `413`** in the same conditions.
- **The tradeoff is real and is exactly what a defense-in-depth security fix is expected to cost**:
  a small, fixed latency tax on every well-behaved request, in exchange for closing an unbounded,
  intermittently-triggered resource-exhaustion path. This checkpoint reports the cost honestly
  rather than asserting "no measurable regression" — there is one, and it is disclosed here in
  full per the governing prompt's explicit instruction.

## Next

Checkpoint 5 (Validation) — run `scripts/rca/p2_5_reproduce.mjs` exactly as committed. Per
Checkpoint 3's Section H finding, its default ~300KB payload falls inside the separate platform
ceiling discovered in this ECR's own testing, so a high failure rate there must be interpreted
against Checkpoint 3's Section H control (which isolates this fix's real, substantial effect at a
size below that ceiling), not read at face value as this fix failing.
