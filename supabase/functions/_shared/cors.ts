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
/// parsed. This is the real backstop: it depends only on bytes actually
/// delivered to the isolate, never on a header a proxy layer can drop or
/// misreport, so it enforces the same outcome whether `Content-Length` is
/// correct, wrong, or absent entirely.
///
/// The `Content-Length` pre-check below is kept only as a fast-path
/// optimization for the common well-behaved case (reject before waiting on
/// the stream at all when the header is both present and already honest
/// about being oversized) — it is never the sole authority; the streaming
/// count always runs and is what actually protects the invocation.
///
/// Single shared utility — every Edge Function that accepts a JSON body
/// must call this instead of `req.json()` directly, so there is exactly one
/// place this guard is implemented.
export async function readBodyGuarded(req: Request): Promise<BodyReadResult> {
  const declaredLen = req.headers.get("content-length");
  if (declaredLen && Number(declaredLen) > MAX_BODY_BYTES) {
    return { ok: false, response: tooLargeResponse() };
  }

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
