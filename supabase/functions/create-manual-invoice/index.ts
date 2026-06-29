// supabase/functions/create-manual-invoice/index.ts
// Owner taps "Passer à Pro/Premium" in SubscriptionPlansScreen — creates a
// pending invoice with a reference for a manual bank transfer; KYNZA's
// team (or the owner, after confirming payment out-of-band) later calls
// the mark_invoice_paid RPC, which flips salons.plan.
import { handleOptions, jsonResponse } from "../_shared/cors.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { createServiceRoleClient, getAuthenticatedUser } from "../_shared/supabase_admin.ts";

// TODO(billing): placeholder — replace with KYNZA's real bank account
// details before any real upgrade request is sent to a client (mirrors
// KynzaConstants.bankTransferInstructions on the Flutter side).
const BANK_TRANSFER_INSTRUCTIONS =
  "Banque : [À CONFIGURER]\n" +
  "Titulaire du compte : KYNZA SARL\n" +
  "Numéro de compte : [À CONFIGURER]\n" +
  "Merci d'inclure la référence ci-dessus dans le motif du virement.";

Deno.serve(async (req) => {
  const preflight = handleOptions(req);
  if (preflight) return preflight;

  try {
    const caller = await getAuthenticatedUser(req);
    if (caller.role !== "owner" || !caller.salon_id) {
      return jsonResponse({ error: "forbidden" }, 403);
    }

    const admin = createServiceRoleClient();
    if (!(await checkRateLimit(admin, `create-manual-invoice:${caller.id}`, 100, 60))) {
      return jsonResponse({ error: "rate_limit_exceeded" }, 429);
    }

    const body = await req.json();
    const planKey = body.plan_key ?? body.planKey;
    if (!planKey) return jsonResponse({ error: "missing_fields" }, 400);

    const { data: plan, error: planError } = await admin
      .from("subscription_plans")
      .select("key, price_bif")
      .eq("key", planKey)
      .eq("is_active", true)
      .maybeSingle();
    if (planError) throw planError;
    if (!plan || plan.key === "free") {
      return jsonResponse({ error: "invalid_plan" }, 400);
    }

    const reference = `KYNZA-${crypto.randomUUID().slice(0, 8).toUpperCase()}`;

    const { data: invoice, error: insertError } = await admin
      .from("invoices")
      .insert({
        salon_id: caller.salon_id,
        plan_key: plan.key,
        amount_bif: plan.price_bif,
        reference,
        payment_instructions: BANK_TRANSFER_INSTRUCTIONS,
      })
      .select()
      .single();
    if (insertError) throw insertError;

    await admin.from("activity_logs").insert({
      salon_id: caller.salon_id,
      user_id: caller.id,
      type_action: "invoice_created",
      new_values: { invoiceId: invoice.id, planKey: plan.key },
    });

    return jsonResponse({ success: true, invoice }, 200);
  } catch (e) {
    const message = e instanceof Error ? e.message : "unknown_error";
    if (message === "unauthenticated") return jsonResponse({ error: message }, 401);
    return jsonResponse({ error: "create_manual_invoice_failed", message }, 500);
  }
});