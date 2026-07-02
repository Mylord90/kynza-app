import { SupabaseClient } from "jsr:@supabase/supabase-js@2";

const LEAPA_API_KEY = Deno.env.get("LEAPA_API_KEY");
const LEAPA_BASE_URL = Deno.env.get("LEAPA_BASE_URL") ?? "https://api.leapa.bi/v1";

export interface LeapaInitiateParams {
  supabase: SupabaseClient;
  idempotencyKey: string;
  amountBif: number;
  method: string;
  phone: string;
}

export interface LeapaInitiateResult {
  status: "processing" | "failed";
  sandbox?: boolean;
}

/// Calls Leapa's payment-initiate endpoint and updates the matching
/// `transactions` row accordingly. Falls back to sandbox mode (marks the
/// transaction "processing" without calling out) when LEAPA_API_KEY isn't
/// configured — Leapa account is still pending approval as of this writing.
/// Shared by create-payment (client-initiated) and proxipay-confirm
/// (staff-initiated in-person) so both stay on the same Leapa contract.
export async function initiateLeapaPayment(
  params: LeapaInitiateParams,
): Promise<LeapaInitiateResult> {
  const { supabase, idempotencyKey, amountBif, method, phone } = params;

  if (!LEAPA_API_KEY) {
    await supabase.from("transactions").update({ status: "processing" }).eq(
      "idempotency_key",
      idempotencyKey,
    );
    return { status: "processing", sandbox: true };
  }

  const leapaRes = await fetch(`${LEAPA_BASE_URL}/payments/initiate`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${LEAPA_API_KEY}`,
      "Idempotency-Key": idempotencyKey,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: amountBif,
      currency: "BIF",
      method,
      phone,
      reference: idempotencyKey,
    }),
  });

  if (!leapaRes.ok) {
    await supabase.from("transactions").update({ status: "failed" }).eq(
      "idempotency_key",
      idempotencyKey,
    );
    return { status: "failed" };
  }

  const leapaData = await leapaRes.json();
  await supabase
    .from("transactions")
    .update({ status: "processing", leapa_reference: leapaData.reference ?? null })
    .eq("idempotency_key", idempotencyKey);

  return { status: "processing" };
}
