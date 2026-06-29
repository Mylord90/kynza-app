import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

/// Backed by rate_limit_buckets/check_rate_limit (service_role-only RPC,
/// fixed-window counter keyed by an arbitrary string — Edge Functions key
/// by `<function-name>:<caller-id>`). Fails open: an outage of the rate
/// limiter itself must never block real traffic.
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
  if (error) return true;
  return data === true;
}