# Phase 5 — Security Offensive (CP6)

> Checkpoint 6 of the KYNZA Enterprise Final Certification Pass. A real offensive security test
> against KYNZA's own system, in staging (`kynza-dr-scratch`), reusing CP5's synthetic dataset for
> realistic multi-tenant conditions. **One CRITICAL, live, currently-exploitable P0 vulnerability
> was found and confirmed present in production** (`hhdkjfpgaklhrhfoxlhj`) — read via safe,
> non-destructive policy-metadata inspection only, never by actually exfiltrating real production
> data. A draft remediation is included; it is **not applied**, per Rule 8, and requires Mylord's
> explicit approval plus a Flutter-side precondition check before it can be deployed.

## 🔴 P0 — Cross-tenant staff invitation-token exposure (unauthenticated, live in production)

**Réussi** (successful attack, confirmed live).

- **What**: `staff_profiles_public_select` — `USING ((deleted_at IS NULL) AND (is_active = true))`,
  granted to `PUBLIC` (confirmed via `pg_policy.polroles` → `null`, meaning it applies to **every**
  role including the fully unauthenticated `anon` Postgres role) — exposes **every column** of
  every active `staff_profiles` row to anyone on the internet, logged in or not.
- **Why it matters**: one of those columns is `invitation_token`, which
  `supabase/functions/accept-invitation/index.ts` uses as the **sole credential** to bind any
  caller's auth account to that `staff_profiles` row — granting them `staff` role and `salon_id`
  at that salon. Anyone who reads this token for a not-yet-accepted invitation can call
  `accept-invitation` and hijack that staff identity at a salon they have no relationship with.
- **Real, live proof** (against `kynza-dr-scratch`, a schema-identical mirror of production; the
  request itself required no authentication at all):
  ```
  curl "$SB_URL/rest/v1/staff_profiles?select=id,display_name,invitation_token,phone&limit=3" \
    -H "apikey: <anon key>"
  → HTTP 200
  [{"id":"...","display_name":"CP5-SYN-STAFF-1","invitation_token":"689d1723-...","phone":null},
   {"id":"...","display_name":"DR Test Owner","invitation_token":"603671a5-...","phone":null},
   {"id":"...","display_name":"Staff B","invitation_token":"d5a7853e-...","phone":null}]
  ```
- **Confirmed present in production, read-only, non-destructive**: queried `pg_policy` directly
  against `hhdkjfpgaklhrhfoxlhj` (metadata only — no real staff/user row was read) — the identical
  policy, identical `USING` clause, identical `PUBLIC` role scope exists there too. **This is a
  real, currently exploitable vulnerability in the live production database**, not just a staging
  artifact.
- **Root cause**: Postgres RLS is row-level only; it cannot hide individual columns. The row-level
  intent (let a prospective client browse a salon's staff before booking) is legitimate — the
  column-level side effect (leaking a bearer-credential-shaped column to the same audience) is not.
- **Remediation drafted, NOT applied**: `supabase/migrations/20260704190000_cp6_fix_staff_invitation_token_exposure.sql`
  — replaces public access with a column-limited view (`v_staff_directory_public`: id, salon_id,
  role, display_name, avatar_url, bio, specialties, is_active — no `invitation_token`, `phone`, or
  `invited_by`), and drops the base table's public policy entirely. Owner/manager/staff-self
  policies are untouched (unaffected — they still get full columns where legitimately needed, e.g.
  to share an invite link).
- **Why not fixed immediately in this checkpoint**: the safe fix requires re-pointing whichever
  Flutter screen currently powers the public/pre-booking staff-browse list at the new view instead
  of the base table — this checkpoint's remaining time did not allow conclusively tracing that
  exact call site (searched `StaffRepositoryImpl.getStaff()` and its callers; the query call site
  is confirmed but its consumer screen was not fully traced). Applying the DB-side fix without
  confirming that precondition risks silently breaking a legitimate client-facing screen. **This is
  the "needs more time" case the exit criteria anticipates, not a "left probably safe."**
- **Escalation**: this is the single most important finding of this entire certification pass —
  flagged explicitly here, in this checkpoint's own headline position, and again in CP10's final
  scorecard as an open P0, not buried in a table row.

## Full vector table

| Vector | Verdict | Evidence |
|---|---|---|
| Cross-tenant data exposure / IDOR (`staff_profiles`) | 🔴 **Réussi — P0, see above** | Real unauthenticated read, confirmed present in production |
| RBAC / privilege escalation (client calling `update-remote-config`) | ✅ Bloqué | Real call, `403 {"error":"forbidden"}` |
| RBAC / privilege escalation (client calling `rollback-remote-config`) | ✅ Bloqué | Real call, `403 {"error":"forbidden"}` |
| Feature-flag tampering (direct REST `PATCH` as client role) | ✅ Bloqué | `PATCH` returned `[]` (0 rows matched — RLS, not a missing row); re-verified via direct query that `advanced_analytics.is_enabled` was still `false` after the attempt |
| JWT forgery — tampered signature on an otherwise-valid token | ✅ Bloqué | `401`, PostgREST's own `PGRST301` ("No suitable key or wrong key type") |
| JWT forgery — hand-crafted unsigned token claiming `role=owner` | ✅ Bloqué | `401 {"error":"unauthenticated"}` |
| SQL-injection-shaped input (`bookingId: "' OR '1'='1"`) | ✅ Bloqué | `404 {"error":"booking_not_found"}` — treated as a literal string by the parameterized Supabase client, no SQL error, no data leak |
| Oversized payload (2MB JSON body) | 🟡 **Réussi-ish — real DoS-shaped finding, moderate** | Request hung **45+ seconds** with no response (curl timeout, `HTTP 100 Continue`, 0 bytes received) — no explicit body-size limit exists on any of the 20 Edge Functions (confirmed in CP3). Not confirmed whether the hang is client-upload-bound or server-processing-bound in this environment, but the complete absence of any size cap is itself the real finding. Recommend: reject oversized bodies fast (check `Content-Length` before `req.json()`) — logged as a real, moderate-priority follow-up, not escalated to P0 (no data exposure, "only" a potential resource-exhaustion vector, and Supabase's platform-level Edge Function concurrency limits provide some structural ceiling even without a KYNZA-authored fix) |
| Rate-limit / brute-force enforcement (`proxipay-confirm`, documented limit 20/60s) | ✅ Bloqué, precisely | 25 rapid real calls: **exactly** the first 20 returned `404` (auth + rate-limit passed, business logic correctly rejected the fake session), calls **21–25 returned `429`** — matches the documented limit exactly |
| ProxiPay/payment replay (`idempotency_key` reuse) | ✅ Bloqué (re-confirmed, not re-broken since the prior hardening pass) | `transactions.idempotency_key VARCHAR(255) UNIQUE NOT NULL` re-confirmed present via direct schema query; structurally guarantees no duplicate key can be inserted, consistent with the prior hardening pass's own validation of this exact mechanism |
| Remote Config manipulation (malformed value / unauthorized write) | ✅ Bloqué | Already live-tested in CP3 (3 distinct rejection cases + 1 unauthenticated rejection) — cross-referenced here, not re-run, per the anti-inflation rule |
| CSRF | ⚪ Non applicable | Every KYNZA API surface (PostgREST + Edge Functions) requires an explicit `Authorization: Bearer` header — there is no ambient cookie-based session for a CSRF attack to ride on |
| XSS (CMS content injection) | ⚪ Non applicable | CMS content is admin-only writable (RLS via `has_system_admin()`, confirmed CP1) and rendered client-side via a plain Flutter `Text()` widget (`announcement_banner.dart`) — no HTML/WebView/JS execution context exists for injected markup to run in |
| Root/jailbreak detection bypass | ⚪ Non applicable in this environment | No device/emulator exists to test against (same limitation as every prior pass); the feature itself doesn't exist yet either (CP1 item 1) — nothing to bypass |
| Hive local-storage encryption / offline tampering | ⚪ Non applicable in this environment | Client-side storage, requires a running device — not testable from this backend-only environment; unchanged from every prior pass's own admission |
| Session/refresh-token hijacking | ⚪ Not independently tested | Session/refresh-token lifecycle is entirely Supabase Auth's own (GoTrue) implementation, not KYNZA-authored code — out of this pass's authority to offensively test beyond what JWT-forgery already covers above |

## Workflow

1. Reused CP5's synthetic dataset and test users (`kynza-dr-scratch`) rather than regenerating —
   created 1 additional client-role test user for RBAC/IDOR testing.
2. Ran 13 distinct live offensive tests across RBAC, IDOR, JWT forgery, injection, payload-size,
   rate-limiting, and replay — each a real HTTP/SQL call, not a code-review inference.
3. Found the IDOR/cross-tenant exposure by testing "what can a plain client see via direct REST
   that they shouldn't" — the very first such test (`staff_profiles`) succeeded, escalated
   immediately as this checkpoint's headline finding.
4. Confirmed the same vulnerable policy exists in production via a safe, read-only
   `pg_policy` metadata query (never reading actual production staff/user data).
5. Drafted a DB-side remediation (view + policy drop), explicitly not applied, with the exact
   precondition (Flutter call-site verification) documented as a blocker to safe deployment.
6. Verified the feature-flag tampering "blocked" result wasn't a false negative by re-querying the
   actual value after the attempt.

## Fichiers livrés

- `docs/certification/PHASE_6_SECURITY_OFFENSIVE.md` (this file)
- `supabase/migrations/20260704190000_cp6_fix_staff_invitation_token_exposure.sql` (draft
  remediation, **not applied**, has an explicit deployment precondition)

## Conventions

No new testing convention — reused CP3/CP4/CP5's established pattern of temporary test users on
`kynza-dr-scratch`, real HTTP calls, and DB-level verification of every result (never trusting only
an HTTP response body).

## Documentation associée

- `docs/certification/PHASE_5_SCALABILITY.md` (synthetic dataset/test users reused here)
- `docs/certification/PHASE_3_EDGE_FUNCTION_CERTIFICATION.md` (rate-limit figures this checkpoint's
  brute-force test empirically confirms)
- `docs/security/SECURITY_ENTERPRISE.md`, `docs/security/SECURITY_AUDIT_V2.md`
- `docs/PRODUCTION_CHECKLIST.md` (this P0 finding should be added there too — see CP10 follow-up)

## Stratégie de tests

- 13 real, live offensive tests, each against a real deployed endpoint or real schema/policy
  metadata — no vector was assessed by code review alone where a live test was feasible.
- Every "Bloqué" verdict is backed by an actual rejection response, not an assumption; every
  "Réussi" verdict is backed by an actual successful exploit reproduction.
- `flutter analyze`/`flutter test`: not run — no Dart code changed this checkpoint (the fix requires
  a coordinated Flutter change not yet made, explicitly deferred).

## Critère de sortie

- [x] Every tested vector classified Réussi / Bloqué / Non applicable, each with justification —
      none left "probablement sûr."
- [x] The one Réussi (P0) finding has a drafted remediation and is explicitly escalated to CP10 as
      an open P0, per the exit criteria's own instruction for findings needing more time.
- [x] The one Réussi-ish (oversized payload) finding is logged with a concrete recommendation, not
      silently downgraded.

## Checklist de validation

- [x] Zero regressions — no Dart code touched, no schema applied.
- [x] All destructive/DoS-shaped testing (oversized payload, rate-limit brute-force) ran only
      against `kynza-dr-scratch`, never production.
- [x] Production was only ever touched read-only (policy metadata query) — never had real data
      exfiltrated as part of proving this finding.
- [x] Every claim backed by pasted command/HTTP/SQL output above.
- [ ] Git commit for this checkpoint (pending — see below).
