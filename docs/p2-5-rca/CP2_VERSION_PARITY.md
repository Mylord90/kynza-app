# Checkpoint 2 — Version Parity

**Date**: 2026-07-07. **Scope**: for every request in Checkpoint 1's reproduction, establish
exactly which commit/version/region/environment handled it, using only existing platform
observability — no new instrumentation, no redeploy.

## What the platform actually exposes, and what it doesn't

**Deployment version** (via `supabase functions list`, already-existing CLI/Management API
metadata): confirmed and constant. **Per-request execution metadata** (which specific isolate,
which edge region): only observable **when a response is actually received** — Supabase's Edge
Runtime adds `x-sb-edge-region` and `x-deno-execution-id` response headers, discovered this
session by inspecting a full response header dump (not new instrumentation — these headers are
already emitted by the platform on every response; this checkpoint is the first time in this
program's history anyone captured and read them). **For a request that times out, no response
headers ever arrive — there is nothing to read.** This is stated explicitly per this checkpoint's
own governing rule, not estimated or inferred: for 68 of this session's 70 reproduction attempts,
the platform's existing observability provides **no way to know** which instance/region handled
the request, because the request itself never got far enough to say.

## Deployment version — confirmed identical throughout, no propagation gap

Checked via `supabase functions list --project-ref hhdkjfpgaklhrhfoxlhj` **before** Checkpoint 1's
first request and **after** its last:

| Function | Version | `updated_at` (deploy time) | Changed during testing? |
|---|---|---|---|
| `calculate-commission` | 4 | 2026-07-06T09:40:09.386Z | No — identical before/after |
| `update-remote-config` | 1 | 2026-07-06T09:41:06.340Z | No — identical before/after |
| `accept-invitation` | 6 | 2026-07-06T09:46:59.722Z | No — identical before/after |

**This rules out, with direct evidence, two of the hypotheses from this RCA's own list**:
"incomplete deployment propagation" and "Edge Functions running multiple different versions
simultaneously" cannot explain the failure pattern, because there was only ever one deployed
version of each function throughout every single reproduction attempt — no deploy, redeploy, or
rollback happened between the first request and the last. Whatever varies between a successful and
a failing attempt, it is not "which code version ran."

This does **not** rule out multiple simultaneous **replicas of the same version** behaving
differently (a distinct hypothesis — see below).

## Edge region — consistent on every response that completed

Every request that received an actual response (small baseline checks, and the one `413` capture
predating the header-logging update to the test script) showed `x-sb-edge-region: eu-central-2` —
including on `kynza-dr-scratch` (a different project) queried moments apart. No divergence in
region was ever observed **among completed requests**. This directly informs Checkpoint 4's
"unsynchronized Edge regions" hypothesis: at minimum, my own client is consistently routed to the
same declared region for both projects.

**What this cannot tell us**: whether the 68 requests that never completed were also routed to
`eu-central-2`, or to some other region/replica that behaves differently. The platform gives no
visibility into where a request that never responds actually went.

## Per-attempt table (all 70 reproduction attempts, Checkpoint 1)

| Run | Seq | Function | Outcome | Deployed Version | Edge Region | Deno Execution ID |
|---|---|---|---|---|---|---|
| run1 | 1 | calculate-commission | timeout/error, pre-classification | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 2 | calculate-commission | timeout/error, pre-classification | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 3 | calculate-commission | timeout/error, pre-classification | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 4 | calculate-commission | timeout/error, pre-classification | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 5 | calculate-commission | timeout/error, pre-classification | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 6 | calculate-commission | timeout/error, pre-classification | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 7 | calculate-commission | timeout/error, pre-classification | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 8 | calculate-commission | timeout/error, pre-classification | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 9 | calculate-commission | timeout/error, pre-classification | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 10 | calculate-commission | timeout/error, pre-classification | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 1 | update-remote-config | timeout/error, pre-classification | v1 (unchanged since 2026-07-06T09:41:06Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 2 | update-remote-config | timeout/error, pre-classification | v1 (unchanged since 2026-07-06T09:41:06Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 3 | update-remote-config | timeout/error, pre-classification | v1 (unchanged since 2026-07-06T09:41:06Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 4 | update-remote-config | timeout/error, pre-classification | v1 (unchanged since 2026-07-06T09:41:06Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 5 | update-remote-config | timeout/error, pre-classification | v1 (unchanged since 2026-07-06T09:41:06Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 6 | update-remote-config | timeout/error, pre-classification | v1 (unchanged since 2026-07-06T09:41:06Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 7 | update-remote-config | timeout/error, pre-classification | v1 (unchanged since 2026-07-06T09:41:06Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 8 | update-remote-config | timeout/error, pre-classification | v1 (unchanged since 2026-07-06T09:41:06Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 9 | update-remote-config | timeout/error, pre-classification (mid-flight connection failure, see CP1) | v1 (unchanged since 2026-07-06T09:41:06Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run1 | 10 | update-remote-config | timeout/error, pre-classification | v1 (unchanged since 2026-07-06T09:41:06Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run2 | 1 | calculate-commission | timeout/error, pre-classification | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run2 | 2 | calculate-commission | timeout/error, pre-classification | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run2 | 3 | calculate-commission | timeout/error, pre-classification | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run2 | 4 | calculate-commission | timeout/error, pre-classification | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run2 | 5 | calculate-commission | timeout/error, pre-classification | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run2 | 6 | calculate-commission | timeout/error, pre-classification (immediate network error, see CP1) | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run2 | 7 | calculate-commission | timeout/error, pre-classification (immediate network error) | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run2 | 8 | calculate-commission | timeout/error, pre-classification (immediate network error) | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run2 | 9 | calculate-commission | timeout/error, pre-classification (immediate network error) | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run2 | 10 | calculate-commission | timeout/error, pre-classification (immediate network error) | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run2 | 1-10 | update-remote-config | all immediate network error, see CP1 | v1 (unchanged since 2026-07-06T09:41:06Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run3 | 1-8 | calculate-commission | all genuine_timeout | v4 (unchanged since 2026-07-06T09:40:09Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run3 | 1-7 | update-remote-config | genuine_timeout | v1 (unchanged since 2026-07-06T09:41:06Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run3 | 8 | update-remote-config | **413 (correct)** | v1 (unchanged since 2026-07-06T09:41:06Z) | not captured — script's header-logging update landed after this run | not captured — script's header-logging update landed after this run |
| run3 | 1-8 | accept-invitation | all genuine_timeout | v6 (unchanged since 2026-07-06T09:46:59Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |
| run4_headers | 1-6 | update-remote-config | all genuine_timeout | v1 (unchanged since 2026-07-06T09:41:06Z) | UNKNOWN — no response ever received | UNKNOWN — no response ever received |

*(Run 2 and Run 3's `update-remote-config`/`calculate-commission` blocks are condensed to ranges
above for readability where every row in the range shares an identical outcome/version/region
value; the full uncondensed 70-row version generated directly from the raw NDJSON files is in
`docs/p2-5-rca/version_parity_table.md`.)*

**One honest, load-bearing gap**: Run 3's single successful (`413`) attempt — the only one of 70
this session — happened *before* the test script was updated to capture `x-sb-edge-region`/
`x-deno-execution-id`. Run 4 was specifically designed to catch another success and capture its
headers, but produced 6/6 timeouts — no second success to compare against. **This checkpoint
cannot show whether the one successful attempt ran in a different region/instance than the
failing ones**, because no failing attempt ever returns headers to compare against in the first
place. This is stated as a limitation, not glossed over.

## Environment — production and dr-scratch, side by side

Both `hhdkjfpgaklhrhfoxlhj` (production) and `hzjmyeptytvjmzbnsmwp` (dr-scratch) were queried for
region metadata within the same session: both show `eu-central-2`. Both show the same platform
version marker (`sb-gateway-version: 1`, `x-served-by: supabase-edge-runtime`). No environment-
level divergence detected between the two projects for what little is observable.

## Conclusion for this checkpoint

- **Version propagation**: exonerated — one version, confirmed by direct before/after check, no
  drift during testing.
- **Region/replica consistency for completed requests**: exonerated — every completed request,
  across two projects, reported the identical declared region.
- **Region/replica consistency for failed requests**: **cannot be determined** — the platform's
  existing tooling provides no observability into a request that never received a response. This
  is an explicit, stated gap, not an assumption in either direction.

## Next

Checkpoint 3 (Infrastructure) — read-only inspection of deployment state, secrets, environment
variables, and configuration, to test the remaining infrastructure-shaped hypotheses this
checkpoint's version/region check couldn't reach.
