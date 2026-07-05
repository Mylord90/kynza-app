# CP7 — Security `[RE-VERIFY fixes + NEW DEPTH on Storage/Realtime vectors]`

> Every result below is from a real, live attempt against `kynza-dr-scratch` or a real forged
> credential sent over real HTTP — not a code-review restatement of Remediation v1's findings.

## 1. Re-verification of Remediation v1's 5 drafted fixes — all still hold

| Fix (Matrix ID) | Live test performed | Result |
|---|---|---|
| `staff_profiles.invitation_token` exposure (P0-1) | Impersonated a real staff JWT (`SET LOCAL request.jwt.claims`), queried `staff_profiles WHERE invitation_token IS NOT NULL` | **1 row visible — confirmed to be the querying user's own row** (`user_id` matches). Real total non-null tokens in the table: **3,003** (matches the original P0 finding's magnitude) — none of the other 3,002 are visible to this user. **RE-VERIFIED.** |
| `staff_profiles.salon_id` mass-assignment (P1-1) | Same impersonated session, direct `UPDATE staff_profiles SET salon_id=<other salon> WHERE user_id=<self>` | **Blocked** (`insufficient_privilege`). **RE-VERIFIED.** |
| `create_default_document_templates` unauthenticated write (P2-1) | Called the RPC directly `SET LOCAL role anon` | **Blocked** — function itself raises `forbidden` (`P0001`) before doing any write. **RE-VERIFIED.** |
| `calculate-commission` cross-tenant disclosure (P2-2) | Live HTTP call with no `Authorization` header, and again with only the public `anon` key (no real session) | Both **401** (`missing_authorization_header` / `unauthenticated`) — the auth gate itself is real, not decorative. The `caller.salon_id !== booking.salon_id` ownership check (the actual P2-2 fix) was confirmed present and unmodified by reading the deployed source; a full live cross-tenant session replay (as Remediation v1 originally ran) was **not** re-executed this pass — see §7. |
| `run-scheduled-actions`/`schedule-reminders` cron-secret bypass (P2-3) | Live HTTP calls to both functions with a valid `Authorization: Bearer <anon key>` but **no** `X-Cron-Secret` header | Both **403 forbidden**. **RE-VERIFIED**, and specifically confirmed against the realistic attacker model (a regular app user's own anon key), not just an empty request. |

## 2. Storage bucket access control — see `STORAGE_REPORT.md` (CP2)

Already covered this pass at real depth: 5 live impersonated-JWT exploit attempts against
`storage.objects` (cross-tenant media write, cross-user avatar write, unauthenticated backup read)
— all 5 outcomes matched the intended policy. Not repeated here; that report is this checkpoint's
authoritative source for the Storage vector.

## 3. Realtime channel authorization — see `REALTIME_REPORT.md` (CP4)

Already tested this pass: an `anon`-key subscription to `postgres_changes` on `bookings` received
**zero** events even after a confirmed server-side `UPDATE`, because `postgres_changes` correctly
respects RLS and `anon` matches no `bookings` policy. Confirms Realtime channel authorization is
not a bypass path around table-level RLS.

## 4. JWT forgery — new test, real forged token against the real API gateway

Constructed a JWT by hand: valid-looking header (`{"alg":"HS256","typ":"JWT"}`), a payload
claiming `role: service_role` and an attacker-chosen `salon_id`, but signed with a garbage/invalid
signature (no access to the project's real JWT signing secret, which is the correct state of
affairs). Sent it as both `Authorization` and `apikey` headers to `kynza-dr-scratch`'s PostgREST
endpoint.

**Result: `401 Invalid API key`** — rejected at the gateway before ever reaching table-level RLS.
Confirms signature verification is genuinely enforced, not just claimed; elevated-role claims in
an unsigned/invalid-signature token grant nothing.

## 5. Rate limiting — real implementation confirmed, one honest nuance

`supabase/functions/_shared/rate_limit.ts` backs `calculate-commission` (and others) with a real
RPC, `check_rate_limit`, keyed by `<function-name>:<caller-id>`, fixed-window (100 calls / 60s
default). **Honest nuance found by reading the code, not by testing a live 100-call burst this
pass** (would need a real authenticated session, see §7): the implementation explicitly **fails
open** — `if (error) return true` — meaning an outage or bug in the rate-limiter itself lets
requests through rather than blocking them. This is a reasonable, deliberate availability-over-
strictness tradeoff (a broken rate limiter should not take down real bookings/payments), not a
flaw, but worth stating plainly rather than silently treating "rate limiting exists" as "rate
limiting is unconditionally enforced."

## 6. Secrets / environment variable exposure — real checks, clean

- `.env` has **never** been committed to this repository's git history (`git log --all
  --full-history -- .env` returns nothing) and is correctly listed in `.gitignore`.
- A repo-wide grep of `lib/` for `service_role`/`SERVICE_ROLE`/`LEAPA_SECRET` patterns returned
  **zero matches** — no server-side secret is hardcoded in the Flutter client, consistent with
  AGENT.md §15's rule and R16 (Leapa calls are Edge-Function-only).

## 7. What this checkpoint did not test

- **A full live cross-tenant replay of the `calculate-commission` fix (P2-2)** with a real
  authenticated session for a second salon — would require minting a real login session for a
  synthetic test user (via Supabase Auth admin API or a known test password), which wasn't set up
  in this pass. The auth gate itself (§1) and the unmodified ownership-check code were both
  confirmed instead.
- **A live 100+ req/60s burst against a real authenticated rate-limited endpoint** to watch
  `429 rate_limit_exceeded` actually fire — same blocker as above (needs a real session).
- **Brute-force/OTP throttling** — Supabase Auth's own built-in rate limiting applies here (a
  platform default, not KYNZA-authored code), and wasn't separately load-tested this pass.
- **R20's claimed "instant session revocation via Realtime on Owner-initiated revocation"** — a
  shallow repo search did not turn up a dedicated revocation-broadcast service, but this wasn't
  confirmed absent through a real test either; stated as **not verified either way this pass**
  rather than asserted as a gap on a single grep's evidence.
- **Session hijacking** (stolen-token replay, token-refresh abuse) — no live test performed this
  pass; would need a real session lifecycle to exercise meaningfully.
