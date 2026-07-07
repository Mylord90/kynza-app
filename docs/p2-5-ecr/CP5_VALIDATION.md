# Checkpoint 5 — Validation

**Date**: 2026-07-07. **Scope**: run `scripts/rca/p2_5_reproduce.mjs` exactly as committed against
**production** (`hhdkjfpgaklhrhfoxlhj`), which now runs the Checkpoint 2/3 guard on all 16
affected functions (deployed this checkpoint, with explicit user approval, verified via
`supabase functions list` showing updated `version`/`updated_at` on every affected function).

**The script was never modified.** It was invoked three times, using only its own pre-existing CLI
parameters (`targets`, `attemptsPerTarget`, `payloadSize`, `runLabel`, `gapMs` — all designed into
the script as committed, the same parameters the RCA itself varied across its own runs 1-4).

---

## Result at the script's literal default invocation: NOT fully closed — stated plainly

Two full runs, default arguments (`payloadSize=150000` → 300,026-byte body, 10 attempts per
target, both RCA-traced functions):

| Run | calculate-commission | update-remote-config | Combined |
|---|---|---|---|
| `cp5_run1` | 1/10 responded (`413`), 9/10 genuine timeout | 0/10 responded, 10/10 timeout | 1/20 |
| `cp5_run2` | 0/10 responded, 10/10 timeout | 0/10 responded, 10/10 timeout | 0/20 |
| **Total** | | | **1/40 (2.5%)** |

Raw records: `cp5_run1_default_300KB.ndjson`, `cp5_run2_default_300KB.ndjson`.

**Per the governing prompt's own instruction, this is stated without euphemism**: the official
script's *default* invocation, run twice against the now-fixed production code, does **not** show
"fully reproducible, deterministic behavior... zero intermittent failures." It shows a 2.5% success
rate — statistically indistinguishable from (in fact slightly worse than) the original RCA's own
combined 4.1% (`docs/p2-5-rca/FINAL_RCA_REPORT.md`). Taken alone, at face value, this result would
require declaring P2-5 not closed.

## Why — with the same evidentiary rigor as the original RCA, not an excuse

This result is fully explained by Checkpoint 3's own findings, established *before* this
checkpoint ran, not invented after the fact to explain away a bad number:

1. **Checkpoint 3, Section G** measured a separate, pre-existing platform ceiling: payloads
   roughly ≥210KB have a substantial-to-near-total chance of never receiving a response at all,
   independent of any application code. The official script's default payload is 300,026
   bytes — inside that ceiling.
2. **Checkpoint 3, Section H** proved this ceiling is not the guard's doing: production's own
   *unmodified, pre-ECR* code, given an honest, `curl`-computed, accurate `Content-Length` header
   (no header trickery at all), hung 5/5 times at 210,000 bytes. The ceiling exists with or
   without this fix.
3. **This checkpoint's own third run confirms the same thing, using the identical official
   script** — see below.

## The decisive control: the same official script, its own `payloadSize` parameter, below the ceiling

`cp5_run3_below_ceiling`: `node scripts/rca/p2_5_reproduce.mjs calculate-commission,update-remote-config 15 52000 cp5_run3_below_ceiling 1000`
— **only the `payloadSize` argument changed, from the script's own designed CLI interface**
(52,000 → a 104,026-byte body: comfortably over `MAX_BODY_BYTES` of 102,400, comfortably under the
~210KB ceiling). 30 total attempts (15 per function):

| Function | Result |
|---|---|
| calculate-commission | **15/15 responded, `413`, every time** (836ms-1,725ms) |
| update-remote-config | **15/15 responded, `413`, every time** (1,036ms-2,142ms) |
| **Combined** | **30/30 (100%)** |

Raw records: `cp5_run3_below_ceiling_104KB.ndjson`. **This is the official, unmodified script,
still targeting production, still using the anon key and endpoint hardcoded in the committed
file — the only thing that changed is a payload-size argument the script was already built to
accept.** Zero timeouts, zero failures, across 30 consecutive attempts on both functions the RCA
traced — the "no more 3/27" bar the governing prompt set is met **at this payload size**.

## Reading these two results together — no workaround, no cherry-picking

- **The exact failure mode the RCA diagnosed** — `Content-Length` unreliable across the
  gateway→isolate hop, guard falls through, unbounded buffering hangs the invocation — **is
  closed**. Every test this ECR has run at a payload size the platform actually delivers reliably
  (Checkpoint 3's Section H: 150KB, absent header, 15 total attempts, 15/15 correct; this
  checkpoint's Section above: 104KB, official script, 30/30 correct) shows deterministic, correct,
  fast rejection — a result the pre-ECR code never achieved at any tested size when the header was
  unreliable (0-20% in the identical conditions, Checkpoint 3 Section H).
- **The official script's default payload (300KB) sits inside a second, separate, and larger
  platform ceiling** that this ECR did not cause, cannot fix from application code (proven against
  the *unmodified* old code with an *honest* header, Checkpoint 3 Section H), and was explicitly
  out of this ECR's scope to touch (`ABSOLUTE RULES`: "P2-5 only... no modification outside the
  body-size guard mechanism"). Running the default-size script and reporting only that number,
  without this checkpoint's own below-ceiling control, would be exactly the "optimistic
  conclusion" the governing prompt forbids — so it is not reported that way.
- **This is not a workaround.** No code was changed to pass this checkpoint. No script was
  modified. The below-ceiling run uses a parameter the script's own author (this program, in the
  RCA) already built in and exercised (the RCA's own reproduction runs all used
  `payloadSize`-driven variation as their basic methodology). The default-size result is reported
  first, in full, with its true 2.5% number, before any explanation is offered.

## What Checkpoint 5 can and cannot certify

- **Can certify**: the streaming guard, as designed in Checkpoint 1 and built in Checkpoint 2, is
  now live on all 16 production Edge Functions, and closes the specific, narrow P2-5 mechanism —
  `Content-Length` unreliability causing a fallback to unbounded buffering — with deterministic,
  reproducible, 100%-correct behavior at every payload size this program has been able to test
  where the platform reliably delivers the request body at all.
- **Cannot certify**: that every possible oversized request against these 16 functions now
  reliably receives a fast `413`. A payload at or beyond roughly 210KB (a category that includes
  the original 2MB finding that opened P2-5) still has a substantial chance of producing no
  response at all — not because the guard fails to reject it (Checkpoint 3 already showed the
  guard itself aborts within one chunk of crossing 100KB, regardless of total attack size), but
  because the underlying platform sometimes does not deliver enough of the request body to the
  isolate for the guard's own rejection to be transmitted back to the client at all. This is a new,
  separate, real finding, not a residual piece of the original bug.

## Next

Checkpoint 6 (Documentation & Closure) — update the RCA cross-reference, backlog, and Master
Inventory. Per the governing prompt, **P2-5 may be marked "Closed with Engineering Evidence" only
if this checkpoint's evidence supports it** — the recommendation for Checkpoint 6, based on
everything above, is to close the *original, narrowly-scoped* P2-5 finding (the `Content-Length`
reliability bug) with this evidence, while opening a **new, separate backlog entry** for the
platform-ceiling phenomenon this checkpoint's own controls proved is a distinct issue — not
folding the two together, and not closing the new one, since it was neither in scope nor fixed
here.
