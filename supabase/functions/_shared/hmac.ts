import { createHmac, timingSafeEqual } from "node:crypto";

/// Always verify against the raw request body (before JSON.parse) — the
/// signature is computed over the exact bytes Leapa sent.
export function verifyLeapaSignature(
  rawBody: string,
  signature: string,
  secret: string,
): boolean {
  const expected = createHmac("sha256", secret).update(rawBody).digest("hex");
  const a = new TextEncoder().encode(expected);
  const b = new TextEncoder().encode(signature);
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

export function buildIdempotencyKey(bookingId: string): string {
  const windowMinute = Math.floor(Date.now() / 60000);
  return `${bookingId}_${windowMinute}`;
}
