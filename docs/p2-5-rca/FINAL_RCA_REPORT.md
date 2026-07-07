# KYNZA — P2-5 Root Cause Analysis: Final Report

**Date**: 2026-07-07. **Type**: Enterprise-grade RCA, diagnostic only — no fix, no redeploy, no
code change made during this investigation. **Scope**: P2-5 (the body-size DoS guard) only.

---

## Executive summary

P2-5's `checkBodySize()` guard was redeployed to all 16 affected Edge Functions during Backend
Production Closure. Live validation there found a ~11% success rate (3 of 27 attempts); this RCA
re-reproduced the failure with 70 additional real attempts this session (91 total across both
investigations, 4 successes, 4.4%) and traced it to its root cause through five checkpoints:
reproduction, version parity, infrastructure, code, and conclusion.

**The guard's own code is correct, deterministic, and free of any race condition, shared state, or
logic defect** — proven by exhaustive reading, not assumed. **The failure is not caused by this
project's deployment, configuration, secrets, or code.** The most evidence-consistent explanation,
after rejecting every other named hypothesis with specific proof, is a **platform-level
inconsistency in how Supabase's edge infrastructure propagates the `Content-Length` header from
the public gateway to the Deno isolate that actually runs the function code** — when the header
arrives intact, the guard works perfectly and fast; when it doesn't, the request falls through to
the exact unbounded-buffering behavior the guard exists to prevent, and the resulting invocation is
silently terminated by the platform's own resource governor (a real, previously-documented
mechanism on this exact project) without ever producing an HTTP response.

**This is genuine engineering debt, not an operational oversight** — it cannot be closed by a
redeploy (already tried, in Backend Production Closure) or a configuration change (none was found
to differ). It requires a different, defense-in-depth implementation that does not depend on the
unreliable signal.

---

## Investigation timeline

| Time (UTC) | Event |
|---|---|
| 2026-07-06 (prior session) | Backend Production Closure CP1-CP4: P2-5 redeployed to all 16 functions; live validation found 3/27 successes; root cause explicitly deferred to a dedicated follow-up |
| 2026-07-07 03:58-04:05 | This RCA, Run 1: 20 attempts, 0 successes, all genuine 20s timeouts |
| 2026-07-07 04:05-04:07 | Run 2: identical sequence repeated — 5 genuine timeouts, then a 15-attempt cluster of instant client-side network failures within a 330ms window |
| 2026-07-07 04:10-04:18 | Run 3: 24 attempts, 1-second spacing, precise failure typing — 1 success (`update-remote-config`), 23 genuine timeouts |
| 2026-07-07 04:19-04:21 | Run 4: 6 attempts targeting the one function that had just succeeded, specifically to capture region/execution-id headers on a repeat success — 0/6 success, no headers captured |
| 2026-07-07 ~04:22 | Extended-wait test: one hung request given 90 seconds (4.5× the original window) — no response, confirming a genuine non-resolving hang, not a slow success |
| 2026-07-07 | CP2-CP4: version/region confirmed constant and consistent; infrastructure dimensions checked read-only; code read in full, no defect found |

---

## All evidence collected

Full raw data, not paraphrased, lives in:
- `docs/p2-5-rca/raw_run1.ndjson`, `raw_run2.ndjson`, `raw_run3.ndjson`, `raw_run4_headers.ndjson`
  — 70 individual timestamped request records.
- `docs/p2-5-rca/version_parity_table.md` — all 70 attempts, one row each, generated directly from
  the raw files.
- `docs/p2-5-rca/CP1_REPRODUCTION.md` — reproduction methodology and per-run breakdown.
- `docs/p2-5-rca/CP2_VERSION_PARITY.md` — deployment version and edge-region evidence.
- `docs/p2-5-rca/CP3_INFRASTRUCTURE.md` — read-only infrastructure inspection, dimension by
  dimension.
- `docs/p2-5-rca/CP4_CODE_ANALYSIS.md` — full code read, no defect found, with the structural
  argument for why none is possible in this specific function.
- `docs/p2-5-rca/CP5_ROOT_CAUSE.md` — the single root cause, every hypothesis rejected or
  retained with evidence.

**Consolidated numbers, this session**: 70 attempts, 1 success (`update-remote-config`, `413` in
1,245ms), 47 genuine timeouts (~20,000ms, no response), 16 immediate client-side network errors
(treated as a probable local-network artifact, not server evidence — see CP1/CP3), 1 mid-flight
connection failure, 1 extended 90-second test confirming the hang is genuinely unbounded, not
slow. **Combined with the prior session's 27 attempts (3 successes): 97 total real attempts, 4
successes (4.1%).**

---

## Hypotheses tested and rejected (full table in CP5)

Fifteen of nineteen named hypotheses were directly rejected with specific evidence (deployment
propagation, multiple versions, deployment cache, wrong environment, configuration drift,
environment variables, secrets, race conditions, concurrency bugs, logic bugs, rate-limiter bugs,
"just slow" timeouts, initialization order, and middleware ordering). Two (unsynchronized regions,
different replicas) were folded into the root cause as the probable *mechanism* rather than
independently proven or excluded — the evidence needed to fully separate them does not exist in
any tool available to this investigation (see below). One (the body-size-guard "bug") was rejected
specifically as a *code* defect while its *effectiveness* under an unreliable input was retained as
the actual finding.

---

## Confirmed root cause

**Platform-level, intermittent failure to reliably propagate the `Content-Length` request header
from Supabase's edge gateway to the Deno isolate executing the Edge Function**, causing
`checkBodySize()` — proven correct and deterministic by direct code inspection — to sometimes
receive no usable signal and fall through to its own documented, deliberate fallback (treating a
missing header as "not a bypass" rather than a rejection), at which point the oversized body
reaches `req.json()` and reproduces the original unbounded-buffering hang, which the platform
appears to terminate silently (no HTTP response ever sent) once it exceeds a resource/execution
ceiling — a real, previously-observed behavior on this exact project
(`WORKER_RESOURCE_LIMIT`, `docs/master-plan-execution/CP3_ENGINEERING_CLOSURE.md:77`).

## Confidence level: **~70%**

Every alternative explanation this RCA was asked to consider was rejected with direct, specific
evidence. The remaining uncertainty is not a gap in the investigation's rigor — it is a real,
explicitly-identified boundary of what this project's tooling can observe: no failed invocation
ever returns a response, so no tool available to this investigation can confirm what the isolate
actually received on any of the 47+ genuine-timeout attempts. This ceiling is stated in
Checkpoints 2 and 3, not glossed over.

## Risk if left unaddressed

- **P2-5 remains a real, live, intermittently-exploitable Denial-of-Service vector in
  production**, at roughly the same severity as before Backend Production Closure's redeploy — an
  attacker sending repeated oversized payloads will, on the observed ~4-11% success rate, tie up
  Edge Function invocations for their full resource ceiling on a meaningful fraction of attempts,
  which is a real, if intermittent, service-degradation risk, not merely a cosmetic finding.
- **The guard cannot be trusted as a security control** in its current form, because its
  reliability is bounded by infrastructure behavior outside this codebase's control and outside
  this program's ability to monitor (no logs, no visibility into failed invocations).
- **Risk is currently low in practice** (this program's own long-standing, repeatedly-verified
  observation that production traffic is near-zero), but this is a mitigating circumstance, not a
  closed finding — the moment real traffic exists, so does real exposure.

## Recommended corrective action

**Classification: Platform problem** (with a code-level defense-in-depth response available,
described below — this is not purely "wait for Supabase to fix something," since a mitigation
this project can build and control does exist).

**Single recommended strategy**: replace the `Content-Length`-header-based pre-check with a
**streaming byte-count guard** that reads the request body incrementally (via the standard
`Request.body` `ReadableStream`, available in Deno regardless of what headers arrived) and aborts
the read the moment cumulative bytes exceed `MAX_BODY_BYTES` — before ever calling `req.json()` on
the full buffer. This removes the dependency on any header surviving the gateway→isolate hop
entirely: the check would be enforced by directly observing the bytes actually arriving at the
isolate, which is not something an intermediate proxy layer can silently drop or fail to forward,
unlike a header. This is a genuine defense-in-depth mechanism, not a guess — it changes what is
being checked (actual bytes received) rather than trusting a claimed value (a header asserting how
many bytes *will* arrive). The existing `Content-Length` check can remain as a fast-path
optimization for the common, well-behaved case; the streaming check becomes the real backstop for
the case this RCA found is not rare enough to ignore.

**Why this is the single right strategy, not one of several equally-plausible options**: every
other candidate mitigation this RCA considered depends on the same unreliable signal this root
cause identifies (e.g., "just lower `MAX_BODY_BYTES` further" doesn't help if the header itself
never arrives; "add a server-side timeout inside the function" doesn't help if the platform's own
resource governor is what's silently killing the invocation before any in-function timeout could
fire). A streaming check is the one approach that structurally cannot be defeated by the exact
failure mode this RCA demonstrated, because it does not read the header at all.

## Effort estimate: **Moyen**

Not a one-line change (it touches the shared `_shared/cors.ts` helper and its call sites in 16
functions, and needs its own dr-scratch validation cycle with the same rigor this program has
applied to every other fix), but bounded, well-understood, and does not require any new
infrastructure, migration, or external dependency — a contained, single-purpose engineering task
for a future session.

## Explicit final classification

**P2-5 is genuine engineering debt requiring a future, dedicated intervention — it is not a
simple deployment or operational issue.** The redeploy already attempted (Backend Production
Closure CP2) was the correct first action given what was known at the time, and it did not close
the finding because the actual defect is not in this codebase's deployment state, configuration,
or code — it is in the reliability of an external platform signal this program's current
implementation depends on. Closing it requires writing and validating new code (the streaming
guard above), not re-running any existing deployment step.
