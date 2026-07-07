# Checkpoint 3 — Infrastructure

**Date**: 2026-07-07. **Scope**: read-only inspection only — no changes made to any component.
For each infrastructure dimension named in the governing prompt: consistent between failing and
succeeding attempts, or not — and where genuinely unobservable, stated as such.

## Deployment propagation state

**Consistent.** Confirmed in Checkpoint 2 via direct before/after `supabase functions list`
checks: one deployed version per function throughout the entire reproduction campaign (70
requests across 4 runs), zero redeploys, zero version drift. Ruled out as a cause.

## Caching layers

**Consistent, and not applicable to the failure shape.** Every response header dump captured this
session shows `CF-Cache-Status: DYNAMIC` (Cloudflare, sitting in front of Supabase's Edge Runtime,
confirmed via `Server: cloudflare` and `CF-Ray` headers) — meaning Cloudflare is correctly treating
every request as dynamic/non-cached, not serving a stale cached response. This is also expected on
first principles: `POST` requests to a `/functions/v1/*` endpoint are not cache-eligible by
default on any CDN. Caching is not a plausible contributor to either the successes or the
failures.

## Edge Runtime behavior

**Two distinct symptoms observed, one bounded, one not:**

1. **Genuine timeout** (47 of 64 fully-classified attempts, Checkpoint 1): the client's full
   request (confirmed fully uploaded via a verbose transcript in the prior Backend Production
   Closure investigation — "upload completely sent off: 110016 bytes") receives **zero response
   bytes** for the entire client-side wait. This session extended that wait to **90 seconds** on
   one attempt (see below) — still nothing. This is not a slow-but-eventually-correct response; it
   is indistinguishable, from the client's vantage point, from a connection that will never
   resolve.
2. **Immediate network error** (16 of 64 attempts): a connection-level failure (`fetch failed`,
   `TimeoutError` ruled out by name/cause inspection) in single-digit-to-low-hundreds of
   milliseconds. All 16 instances clustered tightly in wall-clock time (14 of them within one
   ~330ms window during Run 2) and were immediately followed by normal, fast, correct responses to
   unrelated small requests — this pattern (a short burst, then full recovery) is far more
   consistent with a transient client-side network hiccup (DNS cache refresh, a local connection
   pool issue) than a server-side event, though this cannot be proven with certainty from the
   client side alone. **This failure mode is set aside as a probable client-side artifact and not
   treated as evidence about the guard's own correctness** — Checkpoint 5 explains why it doesn't
   change the root-cause conclusion either way.

**Extended-timeout test, this checkpoint**: one `update-remote-config` attempt was given a
90-second window (4.5× the original reproduction's 20-second cutoff) specifically to see whether
a "hang" is actually a slow-but-eventually-correct response arriving late. Result: **still no
response after 90,030ms** — `TimeoutError`, confirmed by error name, not a network-level failure.
This rules out "the guard is just slow, not broken" as an explanation; whatever is happening does
not resolve within an order of magnitude more time than the original failure window.

**A documented precedent for genuine platform-level resource limits in this exact project**:
`docs/master-plan-execution/CP3_ENGINEERING_CLOSURE.md` records a real `WORKER_RESOURCE_LIMIT`
error hit by `create-platform-backup` when it tried to page through 400,001 rows in one
invocation — direct proof this Supabase project's Edge Runtime does enforce hard resource/time
ceilings that can end an invocation abnormally. This is cited as existing, relevant platform
behavior, not assumed by analogy: it establishes that "an Edge Function invocation can be killed
by the platform without producing a normal HTTP response" is a real, previously-observed mechanism
on this exact project, not a hypothetical.

## Replication / region distribution

**Consistent for every request that completed; unobservable for every request that didn't**
(established in full in Checkpoint 2). `x-sb-edge-region: eu-central-2` on 100% of completed
responses, both projects. No divergence ever observed among the attempts this checkpoint *can*
inspect.

## Environment variables

**Consistent.** `supabase secrets list --project-ref hhdkjfpgaklhrhfoxlhj` re-checked this session:
same 8 secrets (`CRON_SECRET` + 7 platform-managed `SUPABASE_*` defaults) as recorded in Backend
Production Closure CP4 — names and update timestamps unchanged, confirming presence/consistency
without printing any value. Neither `calculate-commission` nor `update-remote-config` reads
`CRON_SECRET` or any custom secret at all (confirmed by reading both files in full during Backend
Production Closure CP1) — environment variables are not a plausible differentiator for this
specific guard's behavior.

## Secrets

**Presence and naming confirmed consistent, values never inspected** (per this checkpoint's own
rule). No secret was added, removed, or rotated between any of the reproduction runs — re-checked
via the same `secrets list` call above, matching Backend Production Closure's last snapshot
exactly.

## Middleware ordering

**Confirmed identical across all three tested functions, no variation.** Read in full this
checkpoint (not re-derived from memory):

```ts
// calculate-commission, update-remote-config, accept-invitation all follow this exact shape:
const preflight = handleOptions(req);
if (preflight) return preflight;

const tooLarge = checkBodySize(req);   // <-- always the very first real check
if (tooLarge) return tooLarge;

// ...auth, rate-limit, business logic follow, all *after* checkBodySize
```

`checkBodySize()` itself (`supabase/functions/_shared/cors.ts:36-45`) is a single synchronous
function: one header read (`req.headers.get("content-length")`), one numeric comparison, no
`await`, no shared module-level state, no loop. There is no ordering ambiguity possible within a
single invocation — the guard either runs first (as written) or the request that reaches this
function never runs it at all for some other reason. Middleware ordering is ruled out as a
contributor; whether the guard's *input* (the header value) is what varies is a question this
checkpoint's read-only tools cannot resolve — see Checkpoint 2's stated observability gap.

## CI/CD deployment history

**No automated pipeline exists** — re-confirmed this checkpoint by re-reading `.github/workflows/
ci.yml`: its only `deploy` job remains an unwired Android-bundle placeholder
(`"No deploy target is wired yet."`). Every Edge Function deployment in this project's history,
including every one touching P2-5, was a manual `supabase functions deploy` CLI invocation. There
is no CI/CD-driven divergence to investigate because there is no CI/CD deployment path for Edge
Functions at all.

## Supabase project configuration

**`supabase/config.toml`'s `[edge_runtime]` section does not apply to hosted functions** — its own
inline comments state its `policy = "per_worker"` setting "enables hot reload during **local**
development," and the section is consumed only by `supabase functions serve` (local dev), never by
`supabase functions deploy` (remote/hosted, what every one of these 16 functions actually runs
under). Confirmed by reading the file directly this checkpoint, not assumed. No per-function
override (`[functions.calculate-commission]`-style config block) exists for any of the three tested
functions — all three use platform defaults, confirmed identical (`verify_jwt=true`,
`import_map=false` for both checked this session).

## Summary — what this checkpoint establishes, and what it cannot

| Dimension | Verdict |
|---|---|
| Deployment propagation | Exonerated (one version throughout, confirmed) |
| Caching | Exonerated (dynamic, non-cached, confirmed on every response) |
| Edge Runtime — is it just slow? | Exonerated (90s window still produced nothing) |
| Edge Runtime — can a real resource-limit kill an invocation silently here? | **Confirmed possible** (documented precedent, this project, `WORKER_RESOURCE_LIMIT`) |
| Region/replica consistency (completed requests) | Exonerated |
| Region/replica consistency (failed requests) | **Cannot be determined** — no observability |
| Environment variables / secrets | Exonerated (consistent, unrelated to this guard anyway) |
| Middleware ordering | Exonerated (single, simple, synchronous, no ordering ambiguity) |
| CI/CD | Not applicable — no pipeline exists to diverge |
| Project configuration | Exonerated (no relevant per-function override; local-only config section confirmed irrelevant) |

**This checkpoint does not fully exonerate infrastructure** — the central open question (does
`Content-Length` reliably reach the Deno isolate on every request, and if not, why) remains
genuinely unresolved, because the platform provides no read-only way to observe it from outside.
Per the governing prompt's own conditional ("Checkpoint 4 only if Checkpoint 3 finds no
infrastructure-level explanation"): this checkpoint finds no infrastructure-level explanation it
can *demonstrate*, but also cannot rule infrastructure out — it can only rule out every
infrastructure dimension that *is* observable. Checkpoint 4 proceeds on that basis: to check
whether the application code itself could produce this pattern, so that if it cannot, the
remaining, undemonstrable-but-not-excluded infrastructure explanation becomes the leading
candidate by elimination, not by default.

## Next

Checkpoint 4 (Code Analysis) — examine `checkBodySize()`, `checkRateLimit()`, and the surrounding
handler code for any concurrency, atomicity, or logic bug that could independently explain a ~3%
success rate.
