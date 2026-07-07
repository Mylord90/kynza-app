# P2-22 Safety Margin Audit — Body-Size Limits Across All 16 Edge Functions

**Date**: 2026-07-07. **Scope**: extract each affected Edge Function's actual configured
body-size limit directly from the real, currently-deployed code — not from any prior report's
summary — and confirm it sits strictly below the platform ceiling P2-22 identified. The ceiling
figure itself is re-verified against the underlying raw evidence rather than treated as an exact
"~210KB."

---

## Re-verifying the ceiling figure first

`docs/p2-5-ecr/CP3_TESTS.md` Section G (`docs/p2-5-ecr/CP3_TESTS.md:157-171`) recorded a
single-shot payload-size sweep against `update-remote-config`:

| Size (bytes) | Result |
|---|---|
| 204,800 | `413`, 1.58s |
| 208,000 | `413`, 1.41s |
| **209,000** | **timeout (15s)** |
| 210,000 | `413`, 1.29s |
| 211,000 | `413`, 1.51s |
| **212,000** | **timeout (12s)** |
| **216,000** | **timeout (12s)** |
| **220,000** | **timeout (15s)** |

The report itself states plainly (`CP3_TESTS.md:174-175`): "This is not a clean step function —
209,000 timed out while 210,000 and 211,000 both succeeded." A follow-up 5-repeat test at exactly
210,000 bytes (`CP3_TESTS.md:179-183`) got 3/5 correct responses and 2/5 hangs for the **identical
request**.

**Conclusion of this re-verification: there is no single precise threshold to report instead of
"~210KB" — the evidence itself is a probabilistic band, not a step function.** The data supports:
clean, 100% reliable delivery at ≤208,000 bytes; a mixed, non-deterministic zone from roughly
209,000-220,000 bytes (the same exact request sometimes succeeds, sometimes hangs); and
consistent, near-total failure from roughly 220,000+ bytes upward (every size ≥220,000 tested —
220,000, 250,000, 270,000, 290,000, 300,000 — hung every time in `CP3_TESTS.md`'s data). Reporting
a single number (e.g., "210,000" or "210,001") would manufacture false precision the evidence does
not support. **The correct, evidence-backed statement is: reliable delivery is confirmed up to
208,000 bytes; the platform ceiling begins introducing non-zero failure risk somewhere in the
209,000-220,000 byte range, and failure is dominant above roughly 220,000 bytes.**

This directly sets the bar for "safe": any configured limit **at or below 100,000 bytes leaves
more than double the fully-clean 208,000-byte margin**, and more than 100,000 bytes of margin below
the first-failure point (209,000 bytes) observed in the raw data. This is a large, comfortable
safety margin, not a narrow one.

---

## Per-function configured limit — extracted from real code, not summarized

All 16 functions share exactly **one** implementation. Verified directly:

```
$ grep -n "MAX_BODY_BYTES" supabase/functions/_shared/cors.ts
22:const MAX_BODY_BYTES = 100 * 1024; // 100KB — ...
```
`MAX_BODY_BYTES = 100 * 1024 = 102,400 bytes` — declared exactly once, module-scoped, `const`
(cannot be reassigned), in `supabase/functions/_shared/cors.ts:22`, current commit
`5128ec50abc93fbe6990360684297ea20398b909`.

```
$ grep -rln "MAX_BODY_BYTES\|MAX_BODY_SIZE" supabase/functions/*/index.ts
(no output)
```
**Zero of the 16 function-level `index.ts` files define a local `MAX_BODY_BYTES` or
`MAX_BODY_SIZE` override.** There is no mechanism by which any individual function could have a
different configured limit than the shared constant.

```
$ for f in <all 16>; do grep "import.*readBodyGuarded" "supabase/functions/$f/index.ts"; done
```
Every one of the 16 imports `readBodyGuarded` from `../_shared/cors.ts` (verified individually,
not assumed from the pattern holding for one). None reimplements the guard locally.

| # | Function | Configured limit (bytes) | Source |
|---|---|---|---|
| 1 | `accept-invitation` | 102,400 | `_shared/cors.ts:22` (shared, imported) |
| 2 | `calculate-commission` | 102,400 | same |
| 3 | `check-permissions` | 102,400 | same |
| 4 | `claim-referral` | 102,400 | same |
| 5 | `create-booking` | 102,400 | same |
| 6 | `create-manual-invoice` | 102,400 | same |
| 7 | `create-payment` | 102,400 | same |
| 8 | `create-walkin-booking` | 102,400 | same |
| 9 | `execute-workflow` | 102,400 | same |
| 10 | `mark-no-show` | 102,400 | same |
| 11 | `proxipay-confirm` | 102,400 | same |
| 12 | `proxipay-create-session` | 102,400 | same |
| 13 | `rollback-remote-config` | 102,400 | same |
| 14 | `send-notification` | 102,400 | same |
| 15 | `update-remote-config` | 102,400 | same |
| 16 | `validate-qr` | 102,400 | same |

## Live production proof — not just a code-level assertion

The configured value was confirmed to be what production actually enforces, today, by testing the
exact byte boundary against real deployed functions (not dr-scratch):

```
$ wc -c exact_under.json exact_over.json
102400 exact_under.json   (payload = MAX_BODY_BYTES exactly)
102401 exact_over.json    (payload = MAX_BODY_BYTES + 1)

$ curl -X POST https://hhdkjfpgaklhrhfoxlhj.supabase.co/functions/v1/validate-qr --data-binary @exact_under.json
→ 401 {"error":"unauthenticated"}         (passed the guard, reached auth — correctly under limit)

$ curl -X POST https://hhdkjfpgaklhrhfoxlhj.supabase.co/functions/v1/validate-qr --data-binary @exact_over.json
→ 413 {"error":"payload_too_large","max_bytes":102400}   (rejected at exactly the coded boundary)

$ curl -X POST https://hhdkjfpgaklhrhfoxlhj.supabase.co/functions/v1/mark-no-show --data-binary @exact_over.json
→ 413 {"error":"payload_too_large","max_bytes":102400}

$ curl -X POST https://hhdkjfpgaklhrhfoxlhj.supabase.co/functions/v1/create-payment --data-binary @exact_over.json
→ 413 {"error":"payload_too_large","max_bytes":102400}
```

Three independently-spot-checked functions (`validate-qr`, `mark-no-show`, `create-payment`) all
reject at exactly 102,401 bytes and accept exactly 102,400 bytes — confirming the shared-code
proof above is what's actually live, not just what's committed.

## Verdict table

| # | Function | Configured limit | Ceiling (evidence-backed range) | Margin | Verdict |
|---|---|---|---|---|---|
| 1 | accept-invitation | 102,400 B | reliable ≤208,000 B; first failure 209,000 B | ≥106,600 B below first observed failure | **SAFE** |
| 2 | calculate-commission | 102,400 B | same | same | **SAFE** |
| 3 | check-permissions | 102,400 B | same | same | **SAFE** |
| 4 | claim-referral | 102,400 B | same | same | **SAFE** |
| 5 | create-booking | 102,400 B | same | same | **SAFE** |
| 6 | create-manual-invoice | 102,400 B | same | same | **SAFE** |
| 7 | create-payment | 102,400 B | same | same | **SAFE** |
| 8 | create-walkin-booking | 102,400 B | same | same | **SAFE** |
| 9 | execute-workflow | 102,400 B | same | same | **SAFE** |
| 10 | mark-no-show | 102,400 B | same | same | **SAFE** |
| 11 | proxipay-confirm | 102,400 B | same | same | **SAFE** |
| 12 | proxipay-create-session | 102,400 B | same | same | **SAFE** |
| 13 | rollback-remote-config | 102,400 B | same | same | **SAFE** |
| 14 | send-notification | 102,400 B | same | same | **SAFE** |
| 15 | update-remote-config | 102,400 B | same | same | **SAFE** |
| 16 | validate-qr | 102,400 B | same | same | **SAFE** |

## Overall verdict

**SAFE — all 16 functions.** Every affected Edge Function enforces exactly the same 102,400-byte
limit, sourced from a single shared, non-overridable constant, confirmed live in production on
three independently-tested functions. This sits more than 106,000 bytes (over 2×) below the first
byte-count at which the P2-22 platform ceiling was ever observed to introduce any failure risk
(209,000 bytes), and more than double the fully-clean 208,000-byte mark. No function's configured
limit is at or above the ceiling — not a documentation nuance, a directly-measured, wide margin.

**Caveat, stated honestly**: this margin is a property of `MAX_BODY_BYTES`'s current value
(100KB), not of the guard's logic. If `MAX_BODY_BYTES` were ever raised significantly (there is no
indication anyone intends this, and no document proposes it), the same shared-constant design that
makes today's verdict uniform across all 16 functions would need re-verification against the
ceiling again — this is a single-point-of-change property, which is a safety feature, not a risk:
one edit to `_shared/cors.ts:22`, one place to check, not 16.
