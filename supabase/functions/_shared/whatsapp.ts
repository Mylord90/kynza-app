// WhatsApp Business Cloud API — free-form text send. WA_TOKEN/WA_PHONE_ID
// live only in Edge Function env vars, never in the Flutter app (R16).
// Best-effort: throws on failure so the caller can record delivery_error,
// but a thrown error here must never propagate past send-notification's
// own top-level catch.
export async function sendWhatsappText(to: string, body: string): Promise<void> {
  const token = Deno.env.get("WHATSAPP_TOKEN");
  const phoneId = Deno.env.get("WHATSAPP_PHONE_NUMBER_ID");
  if (!token || !phoneId) throw new Error("whatsapp_not_configured");

  const res = await fetch(`https://graph.facebook.com/v19.0/${phoneId}/messages`, {
    method: "POST",
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      messaging_product: "whatsapp",
      to: to.replace("+", ""),
      type: "text",
      text: { body },
    }),
  });

  if (!res.ok) throw new Error(`whatsapp_send_failed: ${await res.text()}`);
}
