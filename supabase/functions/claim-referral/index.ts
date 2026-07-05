// supabase/functions/claim-referral/index.ts
// A new or existing user opens com.kynza.app://accept-referral?token=...
// (ReferralClaimScreen) — links the referrals row to the caller and, when
// the referral was tied to a salon, grants a loyalty stamp to both the
// referrer and the newly referred client.
import { logActivity } from "../_shared/audit.ts";
import { checkBodySize, handleOptions, jsonResponse } from "../_shared/cors.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  const tooLarge = checkBodySize(req);
  if (tooLarge) return tooLarge;

  try {
    const caller = await getAuthenticatedUser(req);
    const admin = createServiceRoleClient();
    if (!(await checkRateLimit(admin, `claim-referral:${caller.id}`, 100, 60))) {
      return jsonResponse({ error: "rate_limit_exceeded" }, 429);
    }

    const body = await req.json();
    const referralToken = body.referral_token ?? body.token;
    if (!referralToken) return jsonResponse({ error: "missing_fields" }, 400);

    const { data: referral, error: lookupError } = await admin
      .from("referrals")
      .select("id, referrer_id, salon_id, status, referred_id, reward_stamps")
      .eq("referral_token", referralToken)
      .maybeSingle();

    if (lookupError) throw lookupError;
    if (!referral || referral.referred_id || referral.status !== "pending") {
      return jsonResponse(
        { error: "invalid_referral", message: "Lien d'invitation invalide ou déjà utilisé." },
        400,
      );
    }
    if (referral.referrer_id === caller.id) {
      return jsonResponse(
        { error: "self_referral", message: "Vous ne pouvez pas utiliser votre propre lien." },
        400,
      );
    }

    // Conditional UPDATE re-checks status/referred_id atomically — a
    // double-tap or retry can only ever consume this token once.
    const { data: claimed, error: claimError } = await admin
      .from("referrals")
      .update({ referred_id: caller.id, status: "signed_up" })
      .eq("id", referral.id)
      .eq("status", "pending")
      .is("referred_id", null)
      .select("salon_id, referrer_id, reward_stamps")
      .maybeSingle();

    if (claimError) throw claimError;
    if (!claimed) {
      return jsonResponse(
        { error: "invalid_referral", message: "Lien d'invitation invalide ou déjà utilisé." },
        400,
      );
    }

    let stampGranted = false;
    let salonName: string | null = null;

    if (claimed.salon_id) {
      const stamps = claimed.reward_stamps ?? 1;
      const { data: salon } = await admin
        .from("salons")
        .select("name")
        .eq("id", claimed.salon_id)
        .maybeSingle();
      salonName = salon?.name ?? null;

      for (const clientId of [claimed.referrer_id, caller.id]) {
        const { data: card, error: cardError } = await admin
          .from("loyalty_cards")
          .upsert({ salon_id: claimed.salon_id, client_id: clientId }, { onConflict: "salon_id,client_id" })
          .select("id")
          .single();
        if (cardError) throw cardError;
        for (let i = 0; i < stamps; i++) {
          const { error: stampError } = await admin.rpc("add_loyalty_stamp", { p_card_id: card.id });
          if (stampError) throw stampError;
        }
      }

      await admin.from("referrals").update({ status: "rewarded", reward_granted: true }).eq("id", referral.id);
      stampGranted = true;

      admin.functions.invoke("send-notification", {
        body: {
          userId: claimed.referrer_id,
          event: "loyalty_reward_available",
          salonId: claimed.salon_id,
          data: { salon_name: salonName ?? "", reward: "" },
        },
      }).catch(() => {});
    }

    await logActivity(admin, req, {
      salonId: claimed.salon_id,
      userId: caller.id,
      typeAction: "referral_claimed",
      newValues: { referralId: referral.id, referrerId: claimed.referrer_id },
    });

    return jsonResponse({ success: true, stampGranted, salonName }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "claim_referral_failed", message }, 500);
  }
});