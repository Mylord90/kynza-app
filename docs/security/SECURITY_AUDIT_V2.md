# KYNZA — Security Audit V2

> Phase 5 of the Enterprise Hardening & Production Readiness pass. This is a from-scratch
> re-verification of every item in the phase brief — not a re-statement of `docs/SECURITY.md` or
> `docs/security/SECURITY_ENTERPRISE.md`'s prior claims. Where this audit found those docs wrong
> (not just outdated), it says so explicitly (see `SECURITY_ENTERPRISE.md`'s 2026-07-03 addendum).
> Every ✅ below links to the code/test that proves it, per this pass's Rule 2.

## 1. Certificate pinning — ⏳ Scaffolded, inert by default (not active)

**Before**: confirmed absent — no pinning package, no custom `HttpClient`/`SecurityContext`
anywhere, `Supabase.initialize` used the SDK's default `http.Client()` with normal system CA
validation only.

**After**: `lib/core/security/certificate_pinning_service.dart` — wired into
`Supabase.initialize`'s `httpClient` parameter in `main.dart`. Deliberately **not enabled**:

- `featureFlagEnabled = false` (compile-time kill switch) **and**
- `pinnedCertificateDerBytes = []` (empty — pinning is a no-op even if the flag were flipped).

**Why inert, not fully active**: the technically-correct way to pin in Dart is a restricted
`SecurityContext(withTrustedRoots: false)` populated with the actual certificate's DER bytes —
**not** `HttpClient.badCertificateCallback`, which is a common but incorrect approach: that
callback only fires for certificates that already failed normal validation, so "pinning" logic
placed inside it never runs against a real, validly-signed certificate and provides no actual
protection. Implementing the correct approach requires a verified capture of Supabase's real
certificate from a trusted environment first — guessing or stubbing that byte string would mean
every network call hard-fails the moment pinning is turned on, exactly the "bricks the app on a
legitimate cert rotation" failure mode this pass's own rules warn against. `main.dart` gained one
line (`httpClient: CertificatePinningService.createClient()`) and, with pinning inert, this call
is 100% behaviorally identical to the previous default client — proven by
`test/unit/certificate_pinning_service_test.dart` and a full release build.

**Rotation procedure** (documented, to be run once real bytes are captured): 1) run
`CertificatePinningService.captureCurrentCertificateDer` once against production from a trusted
machine/CI step, 2) commit the resulting bytes into `pinnedCertificateDerBytes`, 3) flip
`featureFlagEnabled = true` only after a full smoke test passes against that pin, 4) repeat
before the pinned certificate expires (Supabase manages cert lifecycle; there is no
programmatic expiry-date visibility from this service, so tracking the renewal calendar is a
manual ops responsibility — flagged honestly as a process gap, not solved by code).

## 2. JWT rotation / refresh token strategy — ✅ Verified correct (SDK defaults, no gap)

Traced the actual vendored `gotrue-2.22.0` behavior for an expired/revoked refresh token
(`gotrue_client.dart` `_executeRefresh`): any non-retryable auth failure triggers
`_removeSession()` + `notifyAllSubscribers(AuthChangeEvent.signedOut)`. `AuthNotifier`
(`lib/features/auth/application/notifiers/auth_notifier.dart`) already handles exactly that
event by setting `AuthUiState.unauthenticated()` — the existing, pre-Phase-5 code. **Result: a
dead refresh token correctly degrades to re-login, never a crash or silent failure** — this was
already true before this phase; no code change was needed, only verification that it was true
(rather than assumed).

## 3. Encryption at rest — ✅ Fixed for the PII-bearing box; ⚪ 2 boxes left plaintext (justified)

| Hive box | Before | After | Rationale |
|---|---|---|---|
| `kynza_prefs` (pending invitation/referral tokens, recent searches) | Plaintext | **`HiveAesCipher`, key in OS Keychain/Keystore via `flutter_secure_storage`** (`lib/core/services/hive_encryption_key_service.dart`) | Highest-priority box — the only one holding bearer-style tokens |
| `kynza_permission_cache` | Plaintext | Left plaintext | Booleans + a UUID key only, no PII/secrets of value outside the app itself |
| `kynza_legal_acceptance_queue` / `kynza_sync_dead_letter` | Plaintext | Left plaintext | `userId` (a UUID) + document/version IDs only — no auth secrets |

`main.dart` opens `kynza_prefs` with a graceful fallback: if an existing (pre-encryption)
install's box can't be decrypted with the new cipher, it's deleted and reopened fresh rather
than crashing — this box is a UI-preference cache, never the source of truth (which lives in
Supabase), so this is an acceptable, non-destructive-to-real-data degrade on the one device that
hits it.

**Session storage (a related, higher-value fix)**: the JWT/refresh token itself was never
actually encrypted, despite `docs/security/SECURITY_ENTERPRISE.md` claiming otherwise (see its
2026-07-03 addendum) — `flutter_secure_storage` was a `pubspec.yaml` dependency but was never
imported/used anywhere in `lib/`, and `Supabase.initialize` had no custom `localStorage`, so
`supabase_flutter` fell back to its own default (`SharedPreferencesLocalStorage` — plain
SharedPreferences XML/plist, **not** Keychain/Keystore). **Fixed**:
`lib/core/services/secure_local_storage.dart` implements `LocalStorage` on top of
`flutter_secure_storage` and is now passed as `authOptions.localStorage` in `main.dart`. This is
arguably the single most impactful fix in this phase — the actual session/refresh token is now
genuinely OS-Keychain/Keystore-encrypted, correcting a real, previously-unverified false claim.

## 4. Encryption in transit — ✅ Verified, one hardening addition

- No `http://` URL found anywhere in `lib/` or `supabase/functions/` outside Supabase-CLI
  local-dev-only config (`supabase/config.toml`, never shipped).
- No raw `dart:io` socket/`HttpClient` usage bypassing TLS anywhere in `lib/`.
- **Added**: `main.dart` now asserts `Env.supabaseUrl.startsWith('https://')` before
  `Supabase.initialize` runs — previously nothing would have caught a misconfigured `http://`
  `--dart-define` value before it reached a build. Debug-mode-only (Dart `assert`), so it costs
  nothing in release and fails loudly in dev/CI instead.

## 5. Secret rotation — ⏳ Documented here for the first time (no runbook existed before)

Full, corrected secret inventory in `docs/SECURITY.md` §8 (fixed 3 wrong names in that table:
`LEAPA_SECRET`→`LEAPA_BASE_URL`, `FCM_KEY`→`FCM_SERVICE_ACCOUNT_JSON`/`FCM_PROJECT_ID`,
`WA_TOKEN`→`WHATSAPP_TOKEN`/`WHATSAPP_PHONE_NUMBER_ID` — verified against the actual
`Deno.env.get(...)` calls in each Edge Function, not assumed from the old table).

**Rotation procedure** (per secret, none require app downtime since Edge Functions read
`Deno.env.get(...)` fresh on each cold start, and Supabase Vault updates propagate to new
function invocations without a redeploy):

1. `LEAPA_API_KEY` — request a new key from Leapa's dashboard, set it via
   `supabase secrets set LEAPA_API_KEY=<new>`, confirm one real `create-payment` call succeeds
   with the new key before considering the old one revoked on Leapa's side.
2. `LEAPA_WEBHOOK_SECRET` — coordinate with Leapa (both sides must change together, since it's a
   shared HMAC secret) — set via `supabase secrets set`, then have Leapa send one test webhook
   before confirming rotation complete.
3. `FCM_SERVICE_ACCOUNT_JSON` / `FCM_PROJECT_ID` — generate a new service account key in the
   Firebase console, set via `supabase secrets set`, verify one real push notification delivers
   before deleting the old service account key in Firebase.
4. `WHATSAPP_TOKEN` — WhatsApp Business API tokens have their own expiry in Meta's dashboard;
   generate a new one there, set via `supabase secrets set`, verify one real WhatsApp send
   succeeds before the old token's natural expiry.

No secret is ever committed to this repo (confirmed — `supabase/functions/**` only ever
`Deno.env.get(...)`s these, never hardcodes a value) and no rotation requires a Flutter app
release (all 4 secrets are Edge-Function-side only, invisible to the client).

## 6. SQL injection audit — ✅ One real risk found and fixed; everything else already safe

- All 7 `.rpc()` calls across every Edge Function pass a hardcoded function name plus bound
  parameters (e.g. `_shared/rate_limit.ts`'s `check_rate_limit` call) — no dynamic identifier or
  string-built SQL anywhere.
- No raw SQL client (`pg`, `postgres://`, `exec_sql`) exists anywhere in `supabase/functions/` —
  everything goes through the Supabase JS client's parameterized PostgREST builder.
- **Real risk found and fixed**: `supabase/functions/create-booking/index.ts` interpolated an
  unvalidated `practitionerId` directly into a PostgREST `.or()` filter string
  (`` `staff_id.eq.${practitionerId},staff_id.is.null` ``) — PostgREST's `.or()` mini-language
  treats commas/dots as filter syntax, unlike `.eq()` which takes its value as a properly bound
  parameter. Run under `createServiceRoleClient()` (RLS bypassed), a crafted value could inject
  additional filter clauses into that specific availability-exceptions read. **Fixed**: a UUID
  shape check (`UUID_RE.test(practitionerId)`) now runs before this value is ever used, rejecting
  malformed input with `400 invalid_practitioner_id`.

## 7. Rate limiting — ✅ Corrected stale doc figure; ✅ closed the one real gap

`docs/security/SECURITY_ENTERPRISE.md` claimed "9 of 18 functions" rate-limited — **re-counted
directly, the real figure was 12 of 18** even before this phase (stale doc, not a code gap).

**Real gap found and fixed**: `leapa-webhook` — externally reachable (Leapa → KYNZA), relied
solely on HMAC signature verification with **zero rate limiting**. Added a global bucket
(`leapa-webhook:global`, 120 req/60s), checked *after* signature verification so an attacker
without the HMAC secret can't burn the legitimate-traffic budget by spamming invalid requests.

The remaining un-rate-limited functions (`execute-workflow`, `run-scheduled-actions`,
`schedule-reminders`, `send-notification`) are all server-to-server/cron-triggered with no
external caller surface (per `docs/EDGE_FUNCTIONS_REFERENCE.md`) — bucket-based rate limiting
doesn't apply the same way there and none was added, to avoid solving a problem that doesn't
exist for those specific functions. `create-backup` already has its own 6h-cooldown mechanism,
a reasonable substitute for its specific use case.

Password reset / signup have no KYNZA-level rate limiting — they call Supabase Auth's SDK
methods directly and rely entirely on GoTrue's own platform-level rate limits (not configured or
documented in this repo). Flagged honestly as relying on platform defaults, not silently assumed
to have custom protection.

## 8. Replay protection (ProxiPay) — ✅ Verified real, not cosmetic

Read `proxipay-confirm/index.ts` in full. There is no literal client-sent nonce or timestamp
field anywhere in this flow (`{ sessionId, method, phone }` is the entire client payload) — every
replay-relevant value is instead derived server-side from persisted state:

- **Idempotent replay guard**: an already-`confirmed` session returns `{ alreadyConfirmed: true }`
  rather than re-executing anything.
- **Expiry check against the server-persisted `expires_at`** (set at session-creation time, a
  3-minute window) — not anything the client sends.
- **Server-computed idempotency key**: `buildIdempotencyKey(bookingId)` =
  `${bookingId}_${Math.floor(Date.now()/60000)}` — a 1-minute-window key the client has zero
  input into, enforced as a `UNIQUE` constraint on `transactions.idempotency_key`.
- **One-way state transition**: `pending → confirmed`, and `proxipay_sessions` has **no client
  `UPDATE` policy at all** — only `proxipay-confirm`'s service-role client can ever flip it.

**Conclusion, precisely**: this is real, DB-anchored replay protection, not a client-trusted
nonce that looks like protection but isn't. The only way to "replay" a confirm call is resending
it while the session is still pending/unexpired, which is handled as an idempotent no-op, not a
silent double-charge.

**Residual gap, not fixed here (low severity, already rate-limited)**: `proxipay-create-session`
has no de-duplication guard — a compromised staff session could spam-create sessions for the
same booking, bounded only by its existing 30 req/60s rate limit, not by an explicit
one-session-per-booking check. Tracked here, not silently assumed solved.

## 9. Regression check

`flutter analyze` = 0 issues. `flutter test` = 278/278 passing (275 + 3 new certificate-pinning
tests). A real `flutter build apk --release --split-per-abi` was run after every native-touching
change in this phase (secure storage, Hive encryption, cert pinning scaffold) and a fresh
`aapt dump permissions` confirmed the release manifest is byte-for-byte identical to Phase 1's
fixed baseline — zero new Android permissions from any Phase 5 change.
