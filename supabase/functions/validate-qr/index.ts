// supabase/functions/validate-qr/index.ts
// Staff/owner/manager scans a client's loyalty QR (loyalty_qr_screen.dart)
// from loyalty_scan_screen.dart — atomically consumes the token, then adds
// a stamp or redeems the reward depending on the card's current count.
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const caller = await getAuthenticatedUser(req);
    if (!["owner", "manager", "staff"].includes(caller.role) || !caller.salon_id) {
      return jsonResponse({ error: "forbidden", message: "Action réservée au personnel du salon." }, 403);
    }

    const admin = createServiceRoleClient();
    if (!(await checkRateLimit(admin, `validate-qr:${caller.id}`, 100, 60))) {
      return jsonResponse({ error: "rate_limit_exceeded" }, 429);
    }

    const body = await req.json();
    const token = body.token;
    if (!token) return jsonResponse({ error: "missing_fields" }, 400);

    // Conditional UPDATE re-checks used_at/expires_at atomically — two
    // staff scanning the same QR at once can only ever consume it once.
    const { data: claimed, error: claimError } = await admin
      .from("loyalty_qr_tokens")
      .update({ used_at: new Date().toISOString(), used_by: caller.id })
      .eq("id", token)
      .eq("salon_id", caller.salon_id)
      .is("used_at", null)
      .gt("expires_at", new Date().toISOString())
      .select("card_id, client_id, salon_id")
      .maybeSingle();

    if (claimError) throw claimError;
    if (!claimed) {
      return jsonResponse({ error: "invalid_qr", message: "QR invalide ou expiré." }, 400);
    }

    const { data: card, error: cardError } = await admin
      .from("loyalty_cards")
      .select("id, stamps_count")
      .eq("id", claimed.card_id)
      .single();
    if (cardError) throw cardError;

    const { data: program } = await admin
      .from("loyalty_programs")
      .select("stamps_required")
      .eq("salon_id", claimed.salon_id)
      .maybeSingle();
    const required = program?.stamps_required ?? 10;

    let action: "stamp" | "redeemed";
    let updatedCard: { stamps_count: number };
    if (card.stamps_count >= required) {
      const { data, error } = await admin.rpc("redeem_loyalty_reward", { p_card_id: card.id });
      if (error) throw error;
      updatedCard = data;
      action = "redeemed";
    } else {
      const { data, error } = await admin.rpc("add_loyalty_stamp", { p_card_id: card.id });
      if (error) throw error;
      updatedCard = data;
      action = "stamp";

      if (updatedCard.stamps_count >= required) {
        const { data: salon } = await admin.from("salons").select("name").eq("id", claimed.salon_id).maybeSingle();
        admin.functions.invoke("send-notification", {
          body: {
            userId: claimed.client_id,
            event: "loyalty_reward_available",
            salonId: claimed.salon_id,
            data: { salon_name: salon?.name ?? "", reward: program?.stamps_required ?? "" },
          },
        }).catch(() => {});
      }
    }

    const { data: clientProfile } = await admin
      .from("users")
      .select("full_name")
      .eq("id", claimed.client_id)
      .maybeSingle();

    await admin.from("activity_logs").insert({
      salon_id: claimed.salon_id,
      user_id: caller.id,
      type_action: action === "redeemed" ? "loyalty_reward_redeemed" : "loyalty_stamp_added",
      new_values: { cardId: claimed.card_id, clientId: claimed.client_id },
    });

    return jsonResponse(
      {
        success: true,
        action,
        clientName: clientProfile?.full_name ?? "",
        stampsCount: updatedCard.stamps_count,
        stampsRequired: required,
      },
      200,
    );
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "validate_qr_failed", message }, 500);
  }
});