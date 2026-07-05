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

/// Rejects an oversized body via `Content-Length` *before* `req.json()`
/// ever buffers/parses it — the actual fix for P2-5 (an unbounded body
/// hangs an Edge Function 45+ seconds parsing it). A missing/absent
/// `Content-Length` header (some clients omit it for chunked bodies) is
/// let through here; it's not a bypass; `req.json()` itself always has to
/// buffer the full body to parse it regardless of this header's presence,
/// so this check is a fast-path rejection for the common case, not the
/// only backstop.
export function checkBodySize(req: Request): Response | null {
  const len = req.headers.get("content-length");
  if (len && Number(len) > MAX_BODY_BYTES) {
    return jsonResponse(
      { error: "payload_too_large", max_bytes: MAX_BODY_BYTES },
      413,
    );
  }
  return null;
}
