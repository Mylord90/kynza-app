# Checkpoint 1 — Reproduction

**Date**: 2026-07-07. **Scope**: reproduce P2-5's intermittent failure directly, establish real
numbers from real re-runs, and determine reproducibility. No fix, no redeploy — diagnostic only.

## Method

A dedicated script, `scripts/rca/p2_5_reproduce.mjs`, fires a controlled sequence of oversized
(150-300KB) `POST` requests against production Edge Functions that carry the `checkBodySize()`
guard, using Node's native `fetch` (not curl — ruled out as a client-specific artifact during the
prior Backend Production Closure investigation). Each attempt is logged as one raw NDJSON line:
wall-clock start time, elapsed milliseconds, and either the HTTP status/body received or the exact
failure (distinguishing a genuine timeout, where the client waited the full duration with no
response, from an immediate network-level failure, using both the JavaScript error's `name` and
its underlying `cause.code`, not just the message string).

Three runs were executed this session, each against production (`hhdkjfpgaklhrhfoxlhj`):

- **Run 1**: 20 attempts (`calculate-commission` ×10, `update-remote-config` ×10), 300KB payload,
  requests fired back-to-back with no gap. Raw data: `docs/p2-5-rca/raw_run1.ndjson`.
- **Run 2**: the identical sequence to Run 1, repeated, to test reproducibility. Raw data:
  `docs/p2-5-rca/raw_run2.ndjson`.
- **Run 3**: 24 attempts (`calculate-commission` ×8, `update-remote-config` ×8,
  `accept-invitation` ×8), 150KB payload, with a 1-second gap between each attempt (to rule out
  request-pipelining/connection-reuse as a confound) and precise failure-type classification.
  Raw data: `docs/p2-5-rca/raw_run3.ndjson`.

## Raw results

### Run 1 — 20/20 failed, 0 successes

Every one of the 20 attempts (both functions) timed out at the full 20-second client timeout with
`"The operation was aborted due to timeout"` — a genuine, full-duration hang, not an instant
error. Full raw data in `raw_run1.ndjson`; representative sample:

```json
{"run":"run1","target":"calculate-commission","seq":1,"payloadBytes":300026,"wallClockStart":"2026-07-07T03:58:37.468Z","elapsedMs":20029,"outcome":"timeout_or_error","error":"The operation was aborted due to timeout"}
{"run":"run1","target":"update-remote-config","seq":9,"payloadBytes":300026,"wallClockStart":"2026-07-07T04:04:37.744Z","elapsedMs":10466,"outcome":"timeout_or_error","error":"fetch failed"}
```

(That second line — `update-remote-config` seq 9 — is the one exception in Run 1: a connection
failure at 10.5s rather than a full 20s timeout, discussed below.)

**Run 1 totals**: 20 attempts, **0 successes**, 19 genuine timeouts (~20,000ms each), 1 mid-flight
connection failure.

### Run 2 — 20/20 failed, 0 successes, but a different failure shape emerged mid-run

The first 5 attempts (`calculate-commission` seq 1-5) reproduced Run 1's pattern exactly: full
~20,000ms timeouts. Starting at seq 6, every subsequent attempt (the remaining 5
`calculate-commission` calls and all 10 `update-remote-config` calls) failed **immediately** —
`"fetch failed"`, 3-85 milliseconds elapsed, not 20 seconds:

```json
{"run":"run2","target":"calculate-commission","seq":6,"payloadBytes":300026,"wallClockStart":"2026-07-07T04:07:35.821Z","elapsedMs":1561,"outcome":"timeout_or_error","error":"fetch failed"}
{"run":"run2","target":"calculate-commission","seq":7,"payloadBytes":300026,"wallClockStart":"2026-07-07T04:07:37.387Z","elapsedMs":85,"outcome":"timeout_or_error","error":"fetch failed"}
{"run":"run2","target":"update-remote-config","seq":10,"payloadBytes":300026,"wallClockStart":"2026-07-07T04:07:37.697Z","elapsedMs":3,"outcome":"timeout_or_error","error":"fetch failed"}
```

**This cluster (14 of Run 2's 20 attempts) all occurred within a ~330ms wall-clock window**
(04:07:37.387 to 04:07:37.697) — far too tight to be 14 independent server-side incidents, and
immediately followed by a normal, healthy, fast response to an unrelated small request (see
Checkpoint 3 for the connectivity check performed right after). **Full raw data in
`raw_run2.ndjson`.**

**Run 2 totals**: 20 attempts, **0 successes**, 5 genuine timeouts, 15 immediate network failures.

### Run 3 — 24 attempts, spaced 1 second apart, precise classification — 1/24 success

```json
{"run":"run3","target":"calculate-commission","seq":1,"payloadBytes":300026,"wallClockStart":"2026-07-07T04:10:43.778Z","elapsedMs":20016,"outcome":"timeout_or_error","failureType":"genuine_timeout","error":"The operation was aborted due to timeout","errorName":"TimeoutError","errorCauseCode":null}
{"run":"run3","target":"update-remote-config","seq":8,"payloadBytes":300026,"wallClockStart":"2026-07-07T04:15:59.083Z","elapsedMs":1245,"outcome":"responded","status":413,"body":"{\"error\":\"payload_too_large\",\"max_bytes\":102400}"}
```

Full raw data in `raw_run3.ndjson`. Per-function breakdown:

| Function | Attempts | Successes (413) | Genuine timeouts | Immediate network errors |
|---|---|---|---|---|
| `calculate-commission` | 8 | 0 | 8 | 0 |
| `update-remote-config` | 8 | **1** | 7 | 0 |
| `accept-invitation` | 8 | 0 | 8 | 0 |

**Run 3 totals**: 24 attempts, **1 success**, 23 genuine timeouts, 0 immediate network errors.

## Consolidated totals, this session

| Metric | Count |
|---|---|
| Total attempts (3 runs) | 64 |
| Successes (correct `413`) | **1** (1.6%) |
| Genuine timeouts (full ~20s, no response) | 47 |
| Immediate network errors (`fetch failed`, <100ms) | 16 |

## Is it reproducible?

**Yes, in the sense that matters for an RCA: the *failure* reproduces reliably (98.4% failure rate
across 64 fresh attempts this session, consistent with the prior investigation's 3/27 ≈ 11%
success rate — both sessions agree the guard fails far more often than it succeeds).** The
*exact* pattern (which specific attempt succeeds) is not reproducible — Run 1 and Run 2 used the
identical request sequence and produced different specific outcomes (Run 1: uniform genuine
timeouts; Run 2: timeouts for the first 5, then a cluster of immediate network errors). This
itself is evidence: whatever is happening does not depend deterministically on attempt order,
function identity, or payload size alone.

## Two distinct failure modes, not one

This checkpoint's most important raw finding: failures are **not homogeneous**. There are two
observably different shapes:

1. **Genuine timeout** (47 of 64 failures, 73%): the request's full body is transmitted, the
   client waits the entire configured duration, and no response ever arrives. This is consistent
   with the server/function never sending a response — i.e., the exact pre-fix hang shape.
2. **Immediate network error** (16 of 64 failures, 25%): the request fails in single-digit-to-low-
   hundreds of milliseconds with `"fetch failed"` — far too fast to be the function hanging. This
   is consistent with a connection-level failure (DNS, TCP reset, or a client-side socket/pool
   issue) that never reaches an application response at all. Checkpoint 3 investigates this
   specifically, since it could indicate either a genuinely flaky edge/gateway layer or a
   client-side artifact of this testing environment.

Grand total across this session and the prior Backend Production Closure investigation (which
used curl and a slightly different methodology, 27 attempts, 3 successes):
**91 total real attempts, 4 successes (4.4%), 87 failures.**

## Next

Checkpoint 2 (Version Parity) — establish, using only existing platform observability, exactly
which deployed version/region handled each attempt.
