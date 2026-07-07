# Checkpoint 2 — Implementation

**Date**: 2026-07-07. **Scope**: replace `checkBodySize()`'s header-only guard with a streaming
byte-count guard, per Checkpoint 1's design, and wire it into every affected Edge Function. No
business logic, public API, schema, or workflow change.

---

## What changed

### 1. Shared utility — `supabase/functions/_shared/cors.ts`

`checkBodySize(req: Request): Response | null` is removed and replaced with:

```ts
export type BodyReadResult =
  | { ok: true; text: string }
  | { ok: false; response: Response };

export async function readBodyGuarded(req: Request): Promise<BodyReadResult>
```

Behavior:

- **Fast path (kept, never the sole authority)**: if `Content-Length` is present and already
  claims a size over `MAX_BODY_BYTES`, reject immediately with `413` without touching the stream
  at all — this preserves the previous fast rejection for well-behaved clients with an honest
  header, at effectively zero cost.
- **Real backstop (new)**: regardless of what the header said (present, absent, honest, or
  lying), the function calls `req.body.getReader()` and reads the standard
  `ReadableStream<Uint8Array>` chunk by chunk, adding each chunk's `byteLength` to a running
  total. The instant that total exceeds `MAX_BODY_BYTES`, it calls `reader.cancel()` (releasing
  the stream immediately, no further chunks requested or buffered) and returns the same `413`
  response. If the stream ends (`done: true`) before the threshold is crossed, the accumulated
  chunks are concatenated once into a single `Uint8Array` and decoded to `string`.
- **No full-body buffering before the check applies**: the size check runs after every single
  chunk as it arrives, not after the whole body is collected — the function never holds more
  than `MAX_BODY_BYTES` (plus at most one in-flight chunk) in memory before it can reject.
- **`req.body` absent** (no body stream at all, e.g. a technically-bodyless POST): returns
  `{ ok: true, text: "" }`, the same effective input `req.json()` would have received (which
  itself throws on an empty body) — preserved for parity, see "Behavioral parity" below.

This is a standard Fetch API `ReadableStream` read loop — `Request.body` is part of the same Fetch
API surface Deno's Edge Runtime already implements and that `req.json()` itself consumes
internally; this implementation just consumes it explicitly, incrementally, and with an early-exit
condition instead of implicitly and all-at-once.

### 2. Call-site migration — all 16 affected Edge Functions

Every function using the guard: `accept-invitation`, `calculate-commission`,
`check-permissions`, `claim-referral`, `create-booking`, `create-manual-invoice`,
`create-payment`, `create-walkin-booking`, `execute-workflow`, `mark-no-show`,
`proxipay-confirm`, `proxipay-create-session`, `rollback-remote-config`, `send-notification`,
`update-remote-config`, `validate-qr`.

Each was migrated identically:

```diff
- import { checkBodySize, handleOptions, jsonResponse } from "../_shared/cors.ts";
+ import { handleOptions, jsonResponse, readBodyGuarded } from "../_shared/cors.ts";
  ...
- const tooLarge = checkBodySize(req);
- if (tooLarge) return tooLarge;
+ const bodyGuard = await readBodyGuarded(req);
+ if (!bodyGuard.ok) return bodyGuard.response;
  ...
- const body = await req.json();
+ const body = JSON.parse(bodyGuard.text);
```

(Destructuring/typed forms — `const { bookingId } = await req.json()`,
`const payload: NotificationPayload = await req.json()` — migrated the same way, replacing only
the right-hand side.)

**Every call site was verified individually** (not assumed identical from one match): all 16 had
exactly one `req.json()` call each (`grep -c`, confirmed before editing), and in 15 of the 16 the
guard read and the parse happen in the same `Deno.serve` closure, so no scoping change was
needed beyond the direct substitution. **`create-booking` was the one exception**, and needed a
real fix, not a mechanical one:

```diff
  Deno.serve(async (req) => {
    ...
    const bodyGuard = await readBodyGuarded(req);
    if (!bodyGuard.ok) return bodyGuard.response;
    const startedAt = Date.now();
-   const response = await handleCreateBooking(req);
+   const response = await handleCreateBooking(req, bodyGuard.text);
    ...
  });

- async function handleCreateBooking(req: Request): Promise<Response> {
+ async function handleCreateBooking(req: Request, bodyText: string): Promise<Response> {
    ...
-   const body = JSON.parse(bodyGuard.text);
+   const body = JSON.parse(bodyText);
```

`create-booking` reads its body inside a separate `handleCreateBooking(req)` helper (added later,
per its own comment, to wrap the handler for latency/status instrumentation) — `bodyGuard` is not
in that function's scope. A blanket textual substitution would have left a reference to an
undefined variable, a runtime `ReferenceError` on every real request to this specific function
(the busiest one in the app). This was caught by reading each file's full structure after the
mechanical edit, not assumed correct from the diff alone, and fixed by threading the already-read
body text through as a parameter — no behavior change, same function boundary, same instrumentation
wrapper.

### Behavioral parity with the old `req.json()` call

- **Malformed JSON**: `JSON.parse(bodyGuard.text)` throws the same `SyntaxError` `req.json()`
  would have, at the exact same point in each function's control flow (inside the existing `try`
  block, before the existing `catch (e)`), producing the same `500` / `unknown_error` response as
  before. This was a deliberate placement choice: the guard call sits *before* the `try` block
  (matching the old `checkBodySize` call site exactly), but the `JSON.parse` call sits *inside* the
  `try` block (matching the old `req.json()` call site exactly) — splitting "read + size-check"
  from "parse" preserves both the original early-rejection point and the original error-handling
  point, rather than collapsing them into one and changing either.
- **Empty body**: `JSON.parse("")` throws `SyntaxError: Unexpected end of JSON input`, the same
  error `req.json()` throws on an empty body — same downstream handling.
- **Oversized body, header present and honest**: same `413`, same speed (fast path, unchanged).
- **Oversized body, header absent or wrong**: previously fell through to `req.json()` and
  reproduced the hang (the entire finding). Now: `413`, deterministically, the moment the streamed
  byte count crosses `MAX_BODY_BYTES` — this is the actual fix and is validated with live evidence
  in Checkpoint 5, not assumed here.

### What did not change

- `MAX_BODY_BYTES` (100KB) — unchanged, same value, same comment explaining its sizing.
- `jsonResponse`, `handleOptions`, `corsHeaders` — untouched.
- Every function's business logic, response shapes, status codes, auth/rate-limit ordering, and
  public request/response contract — untouched. The only observable behavior change is that a
  previously-intermittent scenario (oversized body, unreliable header) now reliably returns `413`
  instead of sometimes hanging.
- No second, function-local reimplementation exists anywhere — all 16 functions import and call
  the same `readBodyGuarded` from `_shared/cors.ts`.

---

## Files touched

```
supabase/functions/_shared/cors.ts                         (guard replaced)
supabase/functions/accept-invitation/index.ts               (call site migrated)
supabase/functions/calculate-commission/index.ts            (call site migrated)
supabase/functions/check-permissions/index.ts                (call site migrated)
supabase/functions/claim-referral/index.ts                   (call site migrated)
supabase/functions/create-booking/index.ts                   (call site migrated + scope fix)
supabase/functions/create-manual-invoice/index.ts             (call site migrated)
supabase/functions/create-payment/index.ts                   (call site migrated)
supabase/functions/create-walkin-booking/index.ts             (call site migrated)
supabase/functions/execute-workflow/index.ts                  (call site migrated)
supabase/functions/mark-no-show/index.ts                      (call site migrated)
supabase/functions/proxipay-confirm/index.ts                  (call site migrated)
supabase/functions/proxipay-create-session/index.ts           (call site migrated)
supabase/functions/rollback-remote-config/index.ts            (call site migrated)
supabase/functions/send-notification/index.ts                 (call site migrated)
supabase/functions/update-remote-config/index.ts              (call site migrated)
supabase/functions/validate-qr/index.ts                       (call site migrated)
```

## Verification performed this checkpoint (static, pre-deploy)

- `grep -rn "checkBodySize"` across the whole repo: zero remaining references in code (only in
  the historical RCA/closure docs, which are left untouched per the governing prompt).
- `grep -c "req.json()"` per file, before editing: confirmed exactly 1 per file, so the blanket
  substitution could not silently miss or double-replace a second call.
- Every edited file re-read in full after the mechanical edit to confirm scope correctness — this
  is how the `create-booking` bug was caught, not by assumption.
- No existing test file references `checkBodySize`, `MAX_BODY_BYTES`, or `readBodyGuarded` — no
  test breakage from the rename.
- Deno CLI is not available in this local environment (confirmed: not on `PATH`, not bundled
  under the project's tool directories) — **no local typecheck/compile could be run this
  checkpoint.** This is stated plainly rather than glossed over; Checkpoint 3 (Tests) and
  Checkpoint 5 (Validation, live against the deployed functions) are what will actually prove
  this compiles and behaves correctly under the real Deno Edge Runtime, not this checkpoint.

## Next

Checkpoint 3 (Tests) — real, evidenced tests: valid payload under limit, over limit, absent
`Content-Length`, wrong `Content-Length` (both directions), genuinely chunked/streamed transfer,
multiple payload sizes, every affected function individually, repeated runs for determinism.
