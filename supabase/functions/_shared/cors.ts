export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function handleOptions(req: Request): Response | null {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  return null;
}

const MAX_BODY_BYTES = 100 * 1024; // 100KB — every real payload in this app
// (booking/payment/invoice/notification bodies) is small structured JSON;
// generous headroom over the largest legitimate one seen in this codebase
// (create-manual-invoice's line-items array) without leaving the door open
// to the 2MB/45s-hang finding (P2-5, `PHASE_6_SECURITY_OFFENSIVE.md`).

function tooLargeResponse(): Response {
  return jsonResponse(
    { error: "payload_too_large", max_bytes: MAX_BODY_BYTES },
    413,
  );
}

export type BodyReadResult =
  | { ok: true; text: string }
  | { ok: false; response: Response };

/// P2-5 ECR (`docs/p2-5-ecr/`): the RCA found `Content-Length` does not
/// reliably survive the Supabase gateway→Deno-isolate hop — when it's lost,
/// the old header-only guard's documented fallback let the request through
/// to `req.json()`, which had to buffer the real oversized body and
/// reproduced the exact unbounded-buffering hang the guard existed to
/// prevent (silently killed by the platform's `WORKER_RESOURCE_LIMIT`, no
/// response ever sent).
///
/// This reads the body from the standard `Request.body` `ReadableStream`
/// incrementally and aborts (cancels the reader) the instant cumulative
/// bytes exceed `MAX_BODY_BYTES` — before the full body is ever buffered or
/// parsed. This is the sole authority, by design: it never reads
/// `Content-Length` at all, so it enforces the same outcome whether the
/// header is correct, wrong, or absent — there is nothing for a proxy layer
/// to drop or misreport that this check depends on.
///
/// An earlier draft of this function kept a `Content-Length` pre-check as a
/// "fast path" for oversized-and-honestly-labeled requests. CP3 testing
/// (`docs/p2-5-ecr/CP3_TESTS.md`) found that keeping any header-driven
/// rejection branch re-introduces a dependency the ECR's mandate rules out
/// outright ("depends only on data actually received, never on a declared
/// header") — and demonstrated that a client which understates its own
/// declared length relative to what it sends does not produce a clean,
/// observable false accept/reject at this layer at all; it hangs at the
/// HTTP framing layer below the isolate, before any application code runs.
/// Since the header cannot be used as a rejection shortcut without
/// re-admitting exactly the dependency this fix exists to remove, and since
/// the streaming count below already aborts within one `MAX_BODY_BYTES`
/// chunk of the true start of the body regardless of size, the header is
/// not read here at all — removing it costs no meaningful performance
/// (measured in `docs/p2-5-ecr/CP4_PERFORMANCE.md`) and removes the
/// dependency entirely rather than partially.
///
/// Single shared utility — every Edge Function that accepts a JSON body
/// must call this instead of `req.json()` directly, so there is exactly one
/// place this guard is implemented.
export async function readBodyGuarded(req: Request): Promise<BodyReadResult> {
  const reader = req.body?.getReader();
  if (!reader) {
    return { ok: true, text: "" };
  }

  const chunks: Uint8Array[] = [];
  let total = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    total += value.byteLength;
    if (total > MAX_BODY_BYTES) {
      await reader.cancel();
      return { ok: false, response: tooLargeResponse() };
    }
    chunks.push(value);
  }

  const combined = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    combined.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return { ok: true, text: new TextDecoder().decode(combined) };
}
