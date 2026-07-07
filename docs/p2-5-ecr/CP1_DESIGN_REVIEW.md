# Checkpoint 1 — Design Review (no code changes in this checkpoint)

**Date**: 2026-07-07. **Scope**: explain, in writing, before any implementation, (1) precisely why
`Content-Length` cannot be the sole trust anchor for `checkBodySize()` in this runtime, and (2)
precisely why a streaming byte-count guard is structurally immune to the same failure mode. This
checkpoint makes no code change — it is the reasoning that Checkpoint 2's implementation must be
held accountable to.

Source documents re-read in full for this checkpoint: `docs/p2-5-rca/FINAL_RCA_REPORT.md`,
`docs/p2-5-rca/CP4_CODE_ANALYSIS.md`, `docs/p2-5-rca/CP5_ROOT_CAUSE.md`,
`scripts/rca/p2_5_reproduce.mjs`, and the current implementation at
`supabase/functions/_shared/cors.ts:22-45`.

---

## 1. Precisely why `Content-Length` cannot be trusted in this runtime

The RCA did not conclude "the header is sometimes wrong" as a guess — it arrived there by
elimination, with each alternative explanation independently rejected by specific evidence
(`CP5_ROOT_CAUSE.md`, hypothesis table). The chain of reasoning this design must respect:

1. **The guard's own code is proven correct and deterministic.** `CP4_CODE_ANALYSIS.md` reads
   `checkBodySize()` in full and shows it is a pure function of one input
   (`req.headers.get("content-length")`) with no shared state, no race window, and no
   check-then-act gap. Given the same header value, it produces the same result every time,
   with no exception. **This rules out a code-level defect as the cause of the observed
   intermittency** — a deterministic pure function cannot itself produce a ~4-11% success rate
   across otherwise-identical requests.

2. **Every non-header explanation was independently rejected with evidence, not by default:**
   deployment propagation and version drift (`CP2_VERSION_PARITY.md` — identical function version
   confirmed before/after all 70 attempts), deployment cache (`CP3_INFRASTRUCTURE.md` —
   `CF-Cache-Status: DYNAMIC` on every response; `POST` is not cache-eligible on any CDN by
   design), configuration/secrets drift between prod and dr-scratch (`CP3` — identical
   `verify_jwt`, `import_map`, secret names/timestamps), race conditions and concurrency bugs
   (`CP4` — no shared mutable state, no check-then-act gap, requests were sequential and
   awaited), rate-limiter interference (`CP4` — `checkRateLimit` runs strictly *after*
   `checkBodySize` in the fixed control flow of every traced function; it cannot affect whether
   the guard itself fires), and "just slow, not actually hung" (`CP3`'s 90-second extended-wait
   test — 4.5× the original window — produced no response at all, not a late success).

3. **What remains, by elimination, is the one thing this program cannot observe from outside:**
   whether the `Content-Length` value that reaches the Deno isolate matches what the client sent.
   `checkBodySize()`'s own existing comment (`cors.ts:31-35`) already documents the necessary
   consequence of trusting a possibly-absent header: *"A missing/absent `Content-Length` header
   ... is let through here; it's not a bypass."* This is the exact seam the RCA's evidence points
   at — not a bug in the guard, but a structural gap in what the guard is allowed to see. When the
   header is missing or wrong on arrival at the isolate, the guard's own documented, deliberate
   design lets the request through to `req.json()`, which must fully buffer the actual oversized
   body — reproducing precisely the unbounded-buffering hang the guard exists to prevent, then
   silently terminated by the platform's own resource governor
   (`WORKER_RESOURCE_LIMIT`, precedented at `docs/master-plan-execution/CP3_ENGINEERING_CLOSURE.md:77`)
   with no HTTP response ever sent — indistinguishable, from any external vantage point, from an
   infinite hang (confirmed by the 90-second test above).

4. **The intermittency itself is diagnostic, not incidental.** A binary, always-broken guard would
   produce 0% success; a purely cosmetic, inert guard would produce 100% failure with zero
   exceptions. The RCA recorded 4 clean, fast, correct `413`s out of 97 total real attempts across
   two sessions (~4.1%) — a pattern consistent with `Content-Length` surviving the
   client→Cloudflare→Supabase-gateway→Deno-isolate hop on a minority of requests and being lost
   (stripped, not yet attached, or read before fully available) on the majority. This is the
   signature of a **distributed-edge propagation inconsistency**, not a fixed, always-on failure
   and not a code defect — both of which were independently excluded above.

**Conclusion**: `Content-Length` is a *claim* asserted by an intermediate layer (client, proxy,
gateway) about how many bytes will arrive. The RCA's evidence shows that claim does not reliably
survive the specific gateway→isolate hop this project's Edge Functions run behind. Any guard that
trusts this claim inherits its unreliability by construction — no amount of correct guard logic
can compensate for an unreliable input, which is exactly what Checkpoint 4 already proved (the
guard is correct; its *effectiveness* is bounded by a signal it does not control).

---

## 2. Precisely why a streaming byte-counter is robust against the same failure mode

The proposed mechanism (RCA `FINAL_RCA_REPORT.md`, "Recommended corrective action") reads the
request body incrementally from the standard `Request.body` `ReadableStream<Uint8Array>` and
aborts the read the instant cumulative bytes exceed `MAX_BODY_BYTES` — before `req.json()` (or any
full-buffer parse) ever runs on the complete body.

Why this is not merely "the same idea with extra steps," but a structurally different trust model:

- **It checks what arrived, not what was declared will arrive.** `Content-Length` is metadata
  about the request, forwarded (or not) by every hop between client and isolate. The stream of
  body bytes is the actual payload delivered directly to the isolate's `Request.body` reader by
  the Deno runtime itself — there is no additional hop between "the isolate observes this" and
  "this is what the isolate has." Whatever hop drops or misreports the `Content-Length` header
  (per Section 1, most plausibly the gateway→isolate propagation step, per CP5's root cause) has
  no equivalent way to drop or misreport bytes the isolate is itself reading one chunk at a time —
  those bytes are the request body, not a claim about it.

- **It fails closed on the exact case that currently fails open.** Today, a missing or
  wrong-on-arrival `Content-Length` causes the guard to let the request through (`cors.ts:31-35`'s
  documented fallback) — the worst-case outcome, because it is precisely the case that reproduces
  the hang. A streaming counter has no equivalent "header absent, let it through" branch to fall
  into: with no header to read at all, it still counts every byte as it is read from the stream
  and still aborts at the same threshold. The two failure inputs the RCA explicitly asked this
  design to survive — *absent* header and *wrong* (under- or over-stated) header — degrade to
  irrelevant metadata once the check stops reading the header at all.

- **It bounds the same resource the guard was built to protect, directly.** The original guard's
  purpose (per its own comment, `cors.ts:28-35`) is to stop `req.json()` from buffering an
  unbounded body and exhausting the invocation's CPU/wall-clock budget
  (`WORKER_RESOURCE_LIMIT`). A streaming counter that aborts once the threshold is crossed
  guarantees the isolate never buffers more than `MAX_BODY_BYTES` (plus at most one
  in-flight chunk) regardless of what any header claimed — it enforces the actual invariant the
  guard exists for (bounded memory/time spent reading the body), rather than a proxy for it
  (a header value that predicts what buffering *would* occur).

- **It does not require trusting *any* new signal.** The mechanism introduces no new dependency
  on platform behavior outside this codebase's control — `Request.body` as a standard
  `ReadableStream` is part of the Fetch API surface Deno's Edge Runtime already implements (the
  same object `req.json()` itself consumes internally today); this design reads it explicitly and
  incrementally instead of implicitly and all-at-once. There is nothing "new" for the
  gateway→isolate hop to interfere with, because this mechanism does not read anything that hop
  forwards as metadata — only the body bytes the isolate itself is handed as it processes the
  request, which is the one thing Checkpoint 2/3 of the RCA already established this program has
  no way to independently corrupt or lose (the alternative would mean the isolate is executing
  with a body it never received, which is a different and unprecedented failure mode this RCA
  found no evidence for).

- **Determinism follows from the same structural argument CP4 already made for the old guard,
  applied to a more reliable input.** `checkBodySize()` today is a pure, deterministic function of
  an unreliable input. A streaming counter is a pure, deterministic function (bytes-read vs.
  threshold) of the request's actual body stream — the one input in this entire chain that the RCA
  found no evidence is ever corrupted or dropped (only the *header describing* it was implicated).
  Given the same bytes actually delivered to the isolate, the outcome is always the same; the RCA's
  evidence gives no reason to expect the body stream itself to be intermittently lost the way the
  header apparently is.

**What this design does not claim**: it does not claim to fix the platform-level propagation
inconsistency CP5 identified (that remains, at ~70% confidence, a Supabase Edge Runtime behavior
outside this codebase's control) — it claims to remove this codebase's *dependency* on that
inconsistent signal entirely, per the RCA's own recommended strategy, by checking a different,
directly-observed quantity instead. `Content-Length` may remain as a fast-path optimization for
the common well-behaved case (per the RCA's own text), but it becomes advisory, never load-bearing
— the streaming counter is what actually protects the invocation's resources.

## 3. Implementation-shape implication (for Checkpoint 2, not built here)

One consequence of Section 2 that Checkpoint 2 must resolve, noted here because it is a direct
result of this design's reasoning, not a new scope item: the current call-site shape —
`checkBodySize(req)` returning `Response | null`, followed later by a separate, independent
`await req.json()` — cannot survive unchanged. A `ReadableStream` can only be consumed once, so a
guard that streams-and-counts the body must be the thing that *produces* the parsed JSON for the
caller (or the raw validated bytes), rather than a side-check that runs before an unrelated second
read of the same stream. This is a mechanical consequence of the streaming trust model in Section
2, not a functional or API change — the 16 call sites will call one guarded-read function instead
of two independent steps, with the same net effect (`413` on oversize, parsed body otherwise) and
zero change to any function's public request/response contract.

---

## Next

Checkpoint 2 (Implementation) — build the shared streaming guard described above as a single
utility in `_shared/cors.ts` (or a dedicated module it exports from), wire it into all 16 affected
Edge Functions, replacing every call site's `checkBodySize` + `req.json()` pair with the single
guarded-read call.
