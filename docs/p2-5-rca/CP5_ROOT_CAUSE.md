# Checkpoint 5 — Root Cause

**Date**: 2026-07-07. **Scope**: exactly one root cause, stated precisely, with every other
hypothesis from this RCA's own list explicitly rejected by the specific evidence that rules it
out.

## The root cause

**Immediate cause**: `checkBodySize()`'s guard depends entirely on `req.headers.get("content-
length")` returning the true size of the incoming body by the time the Deno isolate evaluates it.
This value does not reliably reach the isolate. When it does, the guard fires correctly and fast
(`413` in 1-2 seconds, confirmed 4 times across this program's total testing). When it does not
(silently absent or not yet propagated), `checkBodySize`'s own documented, deliberate fallback —
"a missing/absent `Content-Length` header... is let through here; it's not a bypass" — allows the
request to proceed to `req.json()`, which must fully buffer and parse the actual oversized body.

**Underlying/deep cause**: this buffering-and-parsing of an oversized (100KB-300KB in these tests;
2MB in the original finding) body inside a single Deno isolate invocation consumes the invocation's
CPU/wall-clock resource budget without completing, and the invocation is terminated by the
platform's own resource governor **without ever producing a normal HTTP response** — matching, in
shape, a real, previously-documented mechanism on this exact Supabase project
(`WORKER_RESOURCE_LIMIT`, hit by `create-platform-backup` in a prior campaign, per
`docs/master-plan-execution/CP3_ENGINEERING_CLOSURE.md:77`). From any external vantage point —
curl, Node's `fetch`, this program's own two independent test clients — a silently-terminated
invocation and an infinitely-hung one are indistinguishable: both present as "the connection never
returns a response." Checkpoint 3's 90-second extended-wait test confirms this is not a slow
success arriving late; nothing arrives at all.

**Why this produces ~3-4% success, not 0% or 100%**: this pattern is consistent with the
`Content-Length` header surviving the path from client → Cloudflare → Supabase gateway → Deno
isolate on a minority of requests and being lost (stripped, not yet attached, or read before it's
fully available) on the majority — a distributed-edge propagation inconsistency, not a fixed,
always-on failure (which would produce 0%) and not a cosmetic, inert guard (which would produce
100% failure with no exceptions at all, and this program's total 91 real attempts across two
sessions did record 4 clean, fast, correct `413`s). A binary, deterministic, always-broken guard
cannot produce an intermittent result; a purely code-level bug in a stateless synchronous function
cannot produce an intermittent result either (Checkpoint 4). An intermittent result in a
distributed system, where the same code and the same declared version reliably produce different
outcomes across otherwise-identical requests, is the signature of an infrastructure-layer
propagation inconsistency — not a code defect, not a version mismatch, not a configuration
difference (all three explicitly excluded by direct evidence, not by elimination alone).

## Confidence level

**~70%.** This is not a demonstration with server-side visibility (Checkpoint 2 established, with
evidence, that the platform's existing tooling provides no way to inspect what happens inside a
timed-out invocation from outside it) — it is the single explanation consistent with every piece
of *observable* evidence, arrived at by rejecting every alternative this RCA was asked to
consider, each with its own specific evidence (below), not by default. The residual 30% is
precisely the gap Checkpoint 2 already named explicitly: no tool available to this investigation
can confirm what `Content-Length` value the Deno isolate actually received on a failed attempt,
because a failed attempt never returns anything to inspect.

## Every hypothesis from this RCA's brief, rejected or retained, with evidence

| Hypothesis | Verdict | Evidence |
|---|---|---|
| Incomplete deployment propagation | **Rejected** | CP2: identical function version confirmed via direct `functions list` check immediately before and after all 70 reproduction attempts — zero redeploys occurred during testing |
| Multiple different versions running simultaneously | **Rejected** | CP2: same check — one version per function, no drift |
| Deployment cache | **Rejected** | CP3: `CF-Cache-Status: DYNAMIC` on every response; `POST` requests to this endpoint shape are not cache-eligible on any CDN by design |
| Unsynchronized Edge regions | **Folded into root cause, not independently rejected** | CP2: `x-sb-edge-region: eu-central-2` consistent on every *completed* request (both projects) — but this checkpoint cannot see the region for a request that never completed, so regional inconsistency remains the most plausible **proximate mechanism** for the header-propagation gap, not a ruled-out hypothesis |
| Different replicas | **Same treatment as above** | Same evidence gap — plausible mechanism, not independently provable or excludable |
| Wrong environment targeted | **Rejected** | Every attempt explicitly targeted a confirmed project ref (`hhdkjfpgaklhrhfoxlhj` or `hzjmyeptytvjmzbnsmwp`), logged in every raw record |
| Configuration drift between production and dr-scratch | **Rejected** | CP3: identical `verify_jwt`, `import_map`, edge region, and no per-function config overrides on either project |
| Inconsistent environment variables | **Rejected** | CP3: identical secret names/timestamps between checks; neither traced function reads any custom secret at all |
| Different secrets | **Rejected** | Same evidence; also irrelevant by design (`checkBodySize` reads only the `Content-Length` header, no secret) |
| Race condition | **Rejected** | CP4: `checkBodySize` has no shared mutable state and no check-then-act gap — the structural precondition for a race does not exist in this function |
| Concurrency bug | **Rejected** | CP4: same structural reasoning; additionally, this RCA's own reproduction requests were sequential and awaited, never overlapping, ruling out self-inflicted concurrency as a contributor to what was observed |
| Logic bug | **Rejected** | CP4: the function was read in full and is a single, correct, deterministic expression given its input |
| Rate-limiter bug | **Rejected** | CP4: `checkRateLimit` executes strictly *after* `checkBodySize` in all three traced functions' fixed control flow — it cannot affect whether the guard itself fires |
| Body-size-guard bug (as a code defect) | **Rejected as a code defect; retained as the affected mechanism** | CP4: the guard's own logic is correct; its *effectiveness* depends on an input (the header value) it does not control and cannot verify |
| Supabase platform issue | **Retained — leading candidate** | CP3: a documented precedent exists on this exact project (`WORKER_RESOURCE_LIMIT`) for silent, response-less invocation termination under real resource pressure |
| Edge Runtime limitation | **Retained — folded into root cause** | Same evidence; the specific limitation (`Content-Length` propagation reliability across the gateway→isolate hop) is the proposed mechanism |
| Timeout (the guard is just slow) | **Rejected** | CP3: a 90-second extended wait (4.5× the original reproduction window) produced no response at all — not a late-arriving success |
| Initialization-order issue | **Rejected** | CP4: all three traced functions show the identical fixed order — `handleOptions` → `checkBodySize` → everything else — read directly, not inferred |
| Middleware issue | **Rejected** | CP4: same evidence; the "middleware" here is a single synchronous function call with no ordering ambiguity |
| Any other demonstrable cause | **None found** | Exhaustive code read (CP4) and exhaustive read-only infrastructure check (CP3) surfaced no additional candidate |

## What would raise this from 70% to near-certain

Direct server-side visibility into one failed invocation — specifically, whether the Deno isolate
that handled it ever received a `Content-Length` header at all, and if so, what value. This
program's own tooling (Supabase CLI 2.109.0, no `functions logs` subcommand for hosted projects,
confirmed absent in Checkpoint 2) cannot provide this. It would require either the Supabase
dashboard's Logs Explorer (browser-only, not accessed by this investigation) or a support request
to Supabase itself.

## Next

Checkpoint 6 (Recommendation) — classify this root cause into exactly one category and propose one
corrective strategy, described but not implemented.
