// FCM v1 HTTP API. FCM_SERVICE_ACCOUNT_JSON lives only in Edge Function env
// vars — the Flutter app only ever needs the public google-services.json.
async function getFcmAccessToken(): Promise<string> {
  const raw = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (!raw) throw new Error("fcm_not_configured");
  const credentials = JSON.parse(raw);

  const { default: jwtModule } = await import("npm:jsonwebtoken@9");
  const now = Math.floor(Date.now() / 1000);
  const token = jwtModule.sign(
    {
      iss: credentials.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now,
    },
    credentials.private_key,
    { algorithm: "RS256" },
  );

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${token}`,
  });
  const data = await res.json();
  return data.access_token;
}

export async function sendFcmPush(
  deviceToken: string,
  payload: { title: string; body: string; data?: Record<string, string> },
) {
  const projectId = Deno.env.get("FCM_PROJECT_ID");
  if (!projectId) return; // best-effort — never throw (notifications skill §6)

  try {
    const accessToken = await getFcmAccessToken();
    await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: "POST",
      headers: { Authorization: `Bearer ${accessToken}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        message: {
          token: deviceToken,
          notification: { title: payload.title, body: payload.body },
          data: payload.data ?? {},
        },
      }),
    });
  } catch (_e) {
    // Best-effort: a failed push must never block the caller's main flow.
  }
}
