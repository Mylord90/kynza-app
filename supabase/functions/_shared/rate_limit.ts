import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

/// Backed by rate_limit_buckets/check_rate_limit (service_role-only RPC,
/// fixed-window counter keyed by an arbitrary string — Edge Functions key
/// by `<function-name>:<caller-id>`).
///
/// P2-26 (Master Plan Execution CP2 security audit) flagged this as
/// "fails open" — confirmed still true, and confirmed as the deliberate
/// choice, not an oversight: a rate limiter is the one dependency where
/// failing closed would be worse than the risk it guards against — a
/// transient DB hiccup in `rate_limit_buckets` would otherwise take down
/// every Edge Function that calls this first (most of them), a real
/// availability outage traded for a temporary, bounded rate-limiting gap.
/// What was a genuine gap: the failure was completely silent. Now logged
/// so a real limiter outage shows up in Edge Function logs instead of
/// disappearing — the actual, addressable half of this finding.
export async function checkRateLimit(
  admin: SupabaseClient,
  key: string,
  max = 100,
  windowSeconds = 60,
): Promise<boolean> {
  const { data, error } = await admin.rpc("check_rate_limit", {
    p_key: key,
    p_max: max,
    p_window_seconds: windowSeconds,
  });
  if (error) {
    console.error(`checkRateLimit failed open for key="${key}": ${error.message}`);
    return true;
  }
  return data === true;
}