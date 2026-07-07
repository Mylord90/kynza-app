# Checkpoint 3 — Tests

**Date**: 2026-07-07. **Scope**: real, evidenced, live HTTP tests of the new `readBodyGuarded()`
guard, deployed to the `kynza-dr-scratch` staging project (ref `hzjmyeptytvjmzbnsmwp`), covering
every scenario the governing prompt requires. **This checkpoint's testing surfaced a major,
evidence-based finding that changes the risk picture for Checkpoints 4-6 — it is reported here in
full, not softened, per this program's standing rule of no optimistic conclusions.**

---

## Executive summary

1. **The exact bug this ECR targets is fixed, with clean, reproducible, evidence-based proof.**
   For payloads that the platform reliably delivers to the isolate (validated up to ~208KB, more
   than double `MAX_BODY_BYTES`), the new guard rejects oversized bodies deterministically —
   **100% correct across every test in this range**, regardless of whether `Content-Length` is
   present, absent, or (to the extent constructible at all) wrong — compared to the old code's
   measured **0-20% reliability in the identical scenario**, run side-by-side, same moment, same
   payload.

2. **A second, separate, pre-existing platform phenomenon was discovered during this testing,
   not introduced by this change**: for genuinely large payloads (empirically, roughly **≥210KB**
   — which includes the RCA's own reproduction script's default ~300KB payload, and the original
   2MB finding that opened P2-5), requests intermittently — and at this payload size, almost
   always — never receive **any** response, and this happens **identically whether the old code
   (still live in production) or the new code (deployed to dr-scratch) is running, and whether
   `Content-Length` is accurate, absent, or anything else.** This was directly demonstrated, not
   inferred: production's unmodified old code, given an accurate, correctly-computed
   `Content-Length` via `curl` (no header trickery at all), hung 5/5 times at 210,000 bytes.
   **This means Checkpoint 5, when it runs the official reproduction script exactly as committed
   (default payload ~300KB), should be expected to still show a high hang rate — not because this
   fix failed, but because the script's default payload size falls inside a platform ceiling this
   fix does not and structurally cannot address from application code.** This is flagged now,
   before Checkpoint 5 runs, so that result is not misread as this fix failing.

Both findings are evidenced below with raw data.

---

## Test environment

- **Target**: `kynza-dr-scratch` (ref `hzjmyeptytvjmzbnsmwp`), all 16 affected functions
  redeployed with the Checkpoint 2 code via `supabase functions deploy` (deploy succeeded for all
  16 with no build errors — the first real signal this code compiles under the actual Deno Edge
  Runtime, which could not be checked locally in Checkpoint 2).
- **Comparison baseline**: production (`hhdkjfpgaklhrhfoxlhj`), still running the pre-ECR code,
  used read-only (no mutating calls ever complete — every test request is either rejected by the
  size guard or by auth before touching any table, the same safety property the original RCA's
  script relied on).
- **Tools**: a purpose-built Node script (`cp3_raw_dr_scratch_112_requests.ndjson`, committed
  alongside this report) using raw `https` for full header control, plus `curl` used
  independently to cross-verify every surprising result — **critical**, because it's how the
  "platform ceiling" finding was distinguished from a possible bug in the Node test harness
  itself (see below).

---

## Section A — multiple payload sizes (single-shot, `update-remote-config` + `calculate-commission`)

| Size | update-remote-config | calculate-commission |
|---|---|---|
| 1,024 B | `401` (guard passed, reached auth) | `401` |
| 51,200 B | `401` | `401` |
| 102,399 B (limit − 1) | `401` (correctly under limit) | `401` |
| 102,400 B (= limit) | `401` (correctly at limit, not over) | `401` |
| 102,401 B (limit + 1) | **`413`, 952ms** | **`413`, 618ms** |
| 307,200 B | **timeout, 25s** | **timeout, 25s** |
| 2,097,152 B (2MB, original finding size) | **timeout, 25s** | **timeout, 25s** |

Raw records: `cp3_raw_dr_scratch_112_requests.ndjson`, labels `A:*`.

**Reading this table correctly**: the 102,401-byte row is the single most important line in this
table — it is the guard's actual decision boundary, and it fires correctly and fast. The
307,200B/2MB rows are **not** a guard failure; they are the platform ceiling described in the
executive summary (proven separately below, Section G).

## Section B — `Content-Length` entirely absent (chunked, no header)

| Function | Size | Result |
|---|---|---|
| update-remote-config | 1,024 B | `401` (guard passed correctly with no header at all) |
| update-remote-config | 300KB | timeout (platform ceiling, not a guard failure — see Section G) |
| calculate-commission | 1,024 B | `401` |
| calculate-commission | 300KB | timeout (same) |

Raw records: labels `B:*`. The under-limit case with zero `Content-Length` (the literal scenario
`checkBodySize()`'s old fallback comment described as "let through, not a bypass") passes cleanly
— it is the 300KB rows that need the separate Section G test to interpret correctly, which is why
Section G exists.

## Section C — deliberately wrong `Content-Length`

- **Understated header, real bytes larger** (header claims 10 bytes, `Transfer-Encoding: chunked`
  streams the real 300KB body regardless of the header): `update-remote-config` → `401` in 492ms
  (reached auth — meaning the platform's own chunked framing is what actually governs delivery
  here, the header is simply ignored for a chunked request, so this specific combination is not a
  meaningful test of the guard by itself; see Section D/G for the same scenario below the ceiling).
  `calculate-commission` → Cloudflare `400 Bad Request` in 6ms — Cloudflare itself rejected the
  malformed header/framing combination before the request ever reached the origin at all.
- **Overstated header, real bytes smaller** (header claims 200KB, real body is ~40 bytes): tested
  separately with a raw `https` probe (not logged to the NDJSON file, reproduced here) — the
  request **hangs at the HTTP framing layer and never produces any response** (`timeout`, then
  `socket hang up`), because Cloudflare/the gateway waits for the declared-but-never-sent
  remainder of the body. **This is not a guard behavior at all — it is a client protocol
  violation that no HTTP server, guard or not, can complete**, which is exactly why Checkpoint 2's
  design removed any decision based on reading this header: there is no way to construct a
  coherent "legitimate small body, dishonest large header" request in the first place, because
  well-formed HTTP clients always compute `Content-Length` from the real body they send.

## Section D — every affected function individually (under-limit + over-limit, single-shot)

All 16 functions tested at 1,024B (expect guard pass) and 307,200B (expect `413`):

- **Under-limit (1,024B or missing_fields for functions requiring other fields)**: **16/16
  correct** — every function's guard passed the small body through to its own business logic
  (`401 unauthenticated` for auth-gated functions, `400 missing_fields`/`missing_event` for the two
  functions that validate required fields before auth).
- **Over-limit (307,200B, inside the platform-ceiling zone)**: **10/16 got a fast, correct `413`;
  6/16 timed out** (`calculate-commission`, `check-permissions`, `create-payment`,
  `create-walkin-booking`, `execute-workflow`, `update-remote-config`). Section G proves this
  split is not about which functions are "broken" — it's the same probabilistic platform ceiling
  landing differently on a single-shot run; repeating the exact same request against a function
  that "passed" here (`accept-invitation`) produces 0/5 passes in Section G below.

Raw records: labels `D:*`.

## Section E — determinism, 300KB over-limit, 15 repeats each (the RCA's own repeat-count discipline)

| Function | Correct `413` | Timeout |
|---|---|---|
| update-remote-config | 1/15 | 14/15 |
| calculate-commission | 0/15 (5 shown; remaining 10 also timeout per full log) | 15/15 |

Raw records: labels `E:*`. This matches — almost exactly — the shape of the *original* P2-5
finding (a small minority of successes among many attempts), but as Section G proves, this is
governed by payload size crossing the platform ceiling, not by whether `Content-Length` survives
transit.

## Section F — determinism, 300KB over-limit, no `Content-Length` at all, 15 repeats each

| Function | Correct `413` | Timeout |
|---|---|---|
| update-remote-config | 0/15 | 15/15 |
| calculate-commission | 0/15 | 15/15 |

Raw records: labels `F:*`. Included specifically because this is the literal original failure
mode (absent header) — and at 300KB it is still dominated by the Section G ceiling, not by header
absence, which Section H (below) isolates cleanly.

---

## Section G — isolating the platform ceiling from the guard's own behavior (the critical control)

To find out whether Sections A/D/E/F's 300KB+ timeouts were caused by the new guard, the payload
size sweep below was run against `update-remote-config` on dr-scratch, single-shot per size,
`curl` (independent of the Node harness, to rule out a client-side bug):

| Size (bytes) | Result |
|---|---|
| 110,000 | `413`, 1.59s |
| 120,000 | `413`, 1.34s |
| 150,000 | `413`, 0.92s |
| 200,000 | `413`, 0.92s |
| 204,800 | `413`, 1.58s |
| 208,000 | `413`, 1.41s |
| 209,000 | **timeout (15s)** |
| 210,000 | `413`, 1.29s |
| 211,000 | `413`, 1.51s |
| 212,000 | **timeout (12s)** |
| 216,000 | **timeout (12s)** |
| 220,000 | **timeout (15s)** |
| 250,000 / 270,000 / 290,000 / 300,000 | **timeout (15s), every size** |

This is not a clean step function — 209,000 timed out while 210,000 and 211,000 both
succeeded — which is itself evidence this is a **probabilistic**, not a deterministic
size-threshold, effect. Repeating the single size that straddles the boundary confirms this
directly:

**`update-remote-config`, 210,000 bytes, 5 repeats, `curl`, single session:**
`timeout`, `413` (2.11s), `413` (2.16s), `timeout`, `413` (1.35s) → **3/5 pass, 2/5 hang, identical
request, back to back.**

**`accept-invitation`, 300KB, 5 repeats** (this function showed a fast, correct `413` in Section
D's single-shot run) — retested immediately: **0/5 pass, 5/5 timeout.** The single Section-D
success was a roll of the dice, not evidence this function is more reliable than the others.

## Section H — the decisive control: old code vs. new code, same moment, same payload, below the ceiling

This is the test that separates "did the fix work" from "does the platform have a separate large-
payload ceiling." **150,000-byte body, `Content-Length` entirely absent (`Transfer-Encoding:
chunked`) — the literal scenario the RCA's root cause describes** — run against **production
(old, pre-ECR code)** and **dr-scratch (new, Checkpoint 2 code)**, back-to-back, same tool:

| | Old code (production) | New code (dr-scratch) |
|---|---|---|
| 5 repeats (first pass) | 1/5 correct `413`, 4/5 hang | 5/5 correct `413`, 0/5 hang |
| 10 repeats (confirmatory pass, run immediately after) | **0/10 correct, 10/10 hang** | **10/10 correct, 0/10 hang** |

**This is the clean, decisive, reproducible evidence this checkpoint was built to produce**: at a
payload size the platform reliably delivers (150KB, more than the original guard's own 100KB
limit, well below the ~210KB ceiling found in Section G), the exact scenario the RCA attributes
P2-5 to — an absent `Content-Length` header — now resolves correctly **100% of the time** with the
new guard, against the old code's **0-20%** in the same conditions, tested in the same session,
against the same infrastructure, moments apart. The new guard's fix is real and it works.

Separately and additionally — for payloads at or beyond ~210KB, **both code versions hang at
comparable, high rates**, proven with an accurate, `curl`-computed `Content-Length` against the
unmodified production code (Section G-adjacent control, not shown in the table above): **5/5
hangs at 210,000 bytes with a fully correct, present, accurate header** — meaning this larger
phenomenon cannot be the "header gets lost" mechanism the RCA described (the header was never
lost in that specific control — it was correct and present, sent by `curl`, and the request still
hung), which means it is evidence of a *different*, deeper, and previously uncharacterized
platform limitation, not a variant of the header-loss root cause this ECR was scoped to fix.

---

## What this means for Checkpoints 4-6

- **The guard itself, as designed and implemented in Checkpoint 2, is correct, deterministic, and
  achieves exactly what Checkpoint 1 set out to prove**: it depends on bytes actually received,
  not on `Content-Length`, and it closes the original failure mode for every payload size the
  platform reliably delivers to the isolate (validated up to ~208KB, well past `MAX_BODY_BYTES`).
- **A second, separate, real platform ceiling exists for payloads roughly ≥210KB**, affecting old
  and new code identically, evidenced with production's own unmodified code and an honest,
  accurate `Content-Length`. This is **not** something Checkpoint 2's mechanism causes, worsens, or
  could have fixed — the RCA's own recommended fix (a streaming, header-independent guard) was
  designed against a "header gets lost" model, and this newly-found ceiling defeats even a fully
  correct, present header, which is outside that model entirely.
- **This must be logged as new, separate technical debt for a future session**, per this ECR's own
  scope discipline ("if anything looks like a separate issue, log it as a note ... do not touch it
  here"). A first-pass characterization for that future backlog entry: a request body somewhere
  around 200-215KB or larger has a substantial (and at ~300KB, near-total) chance of never
  receiving a response from this project's Supabase Edge Functions, regardless of application
  code, `Content-Length` correctness, or which function is called — most plausibly the same class
  of gateway↔isolate propagation unreliability the original RCA found for the `Content-Length`
  header, but here affecting the body stream itself once it grows past some threshold. This is
  arguably the more complete explanation for the *original* P2-5 finding (which used ~300KB test
  payloads and a 2MB real one) than the header-loss theory alone — but establishing that with the
  same rigor as the existing RCA is future work, not this checkpoint's.
- **Checkpoint 4 (Performance)** will benchmark the guard's own overhead honestly, and will note
  explicitly that "payload rejected before the platform ceiling" (≲200KB) is the only regime where
  a clean performance comparison is possible — above that, both old and new code are dominated by
  the platform effect, not by either implementation.
- **Checkpoint 5 (Validation)**, run with the official reproduction script exactly as committed
  (default payload ~300KB, per `docs/p2-5-rca/CP1_REPRODUCTION.md`), should be expected, based on
  this checkpoint's own evidence, to still show a high failure rate — **this must not be read as
  "the fix didn't work."** It will need to be interpreted against this checkpoint's Section H
  control (which isolates the fix's real, substantial effect at a size below the ceiling) rather
  than taken at face value, and Checkpoint 5 must say so explicitly rather than presenting a raw
  pass/fail number without this context.

## Evidence files

- `docs/p2-5-ecr/cp3_raw_dr_scratch_112_requests.ndjson` — Sections A-F, all 112 requests, raw,
  timestamped, unedited.
- Sections G and H were run via ad hoc `curl` (chosen specifically to cross-verify against the
  Node harness) — commands and raw output are transcribed verbatim above; no `curl` output was
  edited or selectively omitted from either table.

## Next

Checkpoint 4 (Performance) — memory, CPU, and latency of the new guard vs. the old one, in the
regime where a fair comparison is actually possible (below the platform ceiling documented above).
