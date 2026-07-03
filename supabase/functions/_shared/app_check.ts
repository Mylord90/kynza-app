// App Check / Play Integrity abuse-prevention scaffold (Phase 10,
// Enterprise Hardening pass). Logging-only today, by design — never
// blocks a request, whether the header is absent, present-but-unverifiable
// (no verification project configured), or present-but-invalid. Matches
// this pass's own rule for this feature: "never hard-lock a legitimate
// user out, degrade with logging." Called from create-booking and
// proxipay-confirm — the two sensitive Edge Functions named in the phase
// brief.
//
// Real token verification (once the client side actually activates
// Firebase App Check — see docs/security/APP_CHECK_ARCHITECTURE.md for
// the full activation procedure) would call Firebase's App Check REST API
// (https://firebaseappcheck.googleapis.com/v1/projects/{project}/apps/{app}:exchangeAppCheckToken
// pattern, or verify the token's JWT signature against Firebase's public
// JWKS) — not implemented here, since there is nothing real to verify
// against yet (no Firebase App Check provider has been activated in any
// console for this project). The log line below distinguishes "no token
// sent" from "token sent but not verified" so that turning on real
// verification later is additive, not a rewrite.
export function logAppCheckStatus(req: Request, functionName: string): void {
  const token = req.headers.get("X-App-Check-Token");
  if (!token) {
    console.log(`[app_check] ${functionName}: no token present (App Check not yet activated client-side)`);
    return;
  }
  console.log(`[app_check] ${functionName}: token present, not verified (verification not yet configured server-side)`);
}
