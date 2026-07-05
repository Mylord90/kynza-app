import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

/// P2-7 (Master Inventory: `activity_logs.ip_address`/`device_info` not
/// populated by several Edge Functions despite the columns existing) —
/// this helper already existed but was never actually adopted (every
/// function wrote its own inline `.from("activity_logs").insert(...)`,
/// none of them populating these 2 columns). Fixed here for real: every
/// caller now passes the original `Request` so `ip_address`/`device_info`
/// are captured from it, not left null.
export async function logActivity(
  supabase: SupabaseClient,
  req: Request,
  params: {
    salonId: string;
    userId?: string | null;
    typeAction: string;
    oldValues?: object;
    newValues?: object;
  },
) {
  // Supabase's edge runtime sits behind a proxy — the real client IP is in
  // x-forwarded-for (first entry), never in a direct socket address.
  const forwardedFor = req.headers.get("x-forwarded-for");
  const ipAddress = forwardedFor?.split(",")[0]?.trim() ?? null;
  const deviceInfo = req.headers.get("user-agent") ?? null;

  await supabase.from("activity_logs").insert({
    salon_id: params.salonId,
    user_id: params.userId ?? null,
    type_action: params.typeAction,
    old_values: params.oldValues ?? null,
    new_values: params.newValues ?? null,
    ip_address: ipAddress,
    device_info: deviceInfo,
  });
}
