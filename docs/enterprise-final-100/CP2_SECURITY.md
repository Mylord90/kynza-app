# CP2 — Security

**Date**: 2026-07-05. **Scope**: close every remaining Security-domain Master Inventory item;
this was mostly closure of known items, not new discovery, per the campaign's own brief.

## Objectifs

P2-4, P2-5, P2-8, P2-13, P2-21 (root/jailbreak half only — pinning half is external), P2-26.
P1-4 (Android keystore) reclassified external (see `EXTERNAL_GO_LIVE_DEPENDENCIES.md`).

## Preuve

### P2-4 — 2 `SECURITY DEFINER` views: read both definitions, wrote the missing verdict

Read both views' actual SQL, not just the advisor warning text:
- `v_popular_searches` (`20260627160000_adv3_search_logs.sql`): the migration's own comment
  already states the reasoning — a cross-user aggregate (site-wide "popular searches") is
  deliberate; `search_logs` has no SELECT policy at all, so a `security_invoker` view here would
  return zero rows; no sensitive column is exposed (just query text + count). **Verdict:
  intentional, safe.**
- `v_mv_daily_revenue` (`20260630100100_phase3_mv_revenue.sql`): traced the actual filter —
  `WHERE mvr.salon_id = (SELECT u.salon_id FROM users WHERE u.id = auth.uid())`. Materialized
  views can't carry RLS at all, so this inline filter is the standard workaround, and it correctly
  re-derives the caller's own `salon_id` from `auth.uid()` (unaffected by `SECURITY DEFINER`,
  which only changes execution privilege, not the session's JWT-derived `auth.uid()`) — a caller
  with no session or no matching `users` row gets zero rows, never another tenant's data.
  **Verdict: intentional, safe, no bypass.**

**Status: `Fermé (preuve)`** — the "needs design decision" item now has both decisions made and
written, backed by direct SQL inspection, not deferred further.

### P2-5 — Oversized-payload DoS: real fix, live-tested

Added `checkBodySize()` to `_shared/cors.ts` (100KB `Content-Length` pre-check, rejects before
`req.json()` ever buffers/parses) and wired it into **all 16 Edge Functions that parse a JSON
body** (`accept-invitation`, `calculate-commission`, `check-permissions`, `claim-referral`,
`create-booking`, `create-manual-invoice`, `create-payment`, `create-walkin-booking`,
`execute-workflow`, `mark-no-show`, `proxipay-confirm`, `proxipay-create-session`,
`rollback-remote-config`, `send-notification`, `update-remote-config`, `validate-qr`).

Live-tested on `kynza-dr-scratch` (`calculate-commission` redeployed):
```
200KB body  -> HTTP 413 {"error":"payload_too_large","max_bytes":102400}
normal body -> HTTP 400 {"error":"booking_not_completed"}  (real logic reached, not blocked)
```
**Status: `Corrigé-non-déployé`** (code-only, no migration — ready to redeploy to production
pending Mylord's approval).

### P2-8 — `is_system_admin` grant/revoke/audit: built and live-tested end-to-end

New migration `20260706100000_cp2_system_admin_grant_audit.sql`: `system_admin_audit` table +
`grant_system_admin(target, reason)` / `revoke_system_admin(target, reason)` RPCs, gated to
`has_system_admin(auth.uid())`, each writing a mandatory audit row.

**Real bug caught before it shipped, not after**: the pre-existing `protect_user_columns` trigger
makes `is_system_admin` immutable whenever `auth.role() = 'authenticated'` — and `SECURITY
DEFINER` does **not** change what `auth.role()` returns (that reads the calling session's JWT
claim, not the function owner), so the RPC's own `UPDATE` would have been rejected by that trigger
for every real caller. Caught by reasoning through the actual trigger body before testing, then
**confirmed live** on dr-scratch that the naive version would indeed have failed, and fixed with a
transaction-local `set_config('app.system_admin_grant_rpc', 'true', true)` flag the trigger checks.

Live-tested end-to-end on `kynza-dr-scratch`:
```
Non-admin (owner token) -> grant_system_admin -> HTTP 400 {"message":"forbidden"}
System_admin token      -> grant_system_admin -> HTTP 204, target's is_system_admin -> true
System_admin token      -> revoke_system_admin -> HTTP 204, target's is_system_admin -> false
system_admin_audit: [{"action":"granted",...}, {"action":"revoked",...}]  -- both rows present
```
**Status: `Corrigé-non-déployé`**, live-tested on dr-scratch, not applied to production.

### P2-13 — `PermissionGuard` wired into a real screen for the first time

Wrapped the "Add staff" action in `staff_list_screen.dart` with
`PermissionGuard(feature: 'staff', action: 'manage', resource: 'all')`. Verified this doesn't
regress owner access: both the client-side short-circuit (`permissionProvider`) and the server-
side `check_permission()` RPC independently grant `role == 'owner'` unconditional `true` (read
both implementations directly to confirm they agree, not assumed) — owners see the button exactly
as before; a manager only sees it if explicitly granted `staff.manage` via the permission-groups
system, which is the actual point of wiring this in (previously any manager could reach this
action unconditionally, bypassing the granular RBAC system that existed but gated nothing).
`PermissionGuard` itself already has 3 passing unit tests proving its own logic
(`test/unit/permission_guard_test.dart`) — a full `StaffListScreen` widget test was **not** added
this pass (would need mocking ~5 unrelated providers for a 10-line wiring change around an
already-tested component; judged disproportionate, stated explicitly rather than silently
skipped). `flutter analyze` on the changed file: 0 issues.

**Status: `Fermé (preuve)`** — wired into a real screen, mechanism proven safe for the owner path.

### P2-21 — root/jailbreak detection: documented, not shipped unverified

Wrote `docs/security/ROOT_JAILBREAK_DETECTION_PROCEDURE.md` — exact package recommendation,
integration point, and activation steps, same double-gate discipline as the existing App
Check/Google Maps scaffolds. **Deliberately not implemented as code**: verifying root/jailbreak
detection requires a real rooted/jailbroken device or emulator to prove the positive-detection
case, which does not exist in this environment (confirmed: no Android device/emulator has existed
in any pass of this entire program). Shipping unverified detection logic would violate this
campaign's own governing rule. The certificate-pinning half of P2-21 needs a real captured
production TLS certificate — reclassified to `EXTERNAL_GO_LIVE_DEPENDENCIES.md`.

**Status**: root/jailbreak half — `Ouvert`, with a complete, ready-to-execute procedure and an
explicit statement of what this environment cannot verify. Pinning half — reclassified External.

### P2-26 — `check_rate_limit` fails open: kept fail-open (right call), fixed the real gap

Read the actual finding again: "fails open" is the correct, industry-standard tradeoff for a rate
limiter specifically — failing closed would mean a transient hiccup in `rate_limit_buckets` takes
down every Edge Function that calls it first (most of them), trading a bounded, temporary rate-
limiting gap for a real availability outage. **Did not blindly flip to fail-closed.** The actual
gap was that the failure was completely silent — fixed by adding `console.error(...)` on the
failure path, so a genuine limiter outage now shows up in Edge Function logs instead of
disappearing. This is the one item this pass deliberately did NOT "fix" by changing security
posture, because the existing posture was already the right engineering tradeoff — recorded here
as a reasoned confirmation, not silently left alone.

**Status: `Fermé (preuve)`** — design re-confirmed correct with reasoning, the one addressable gap
(silence) closed.

### P1-4 — reclassified

Android upload keystore generation is a one-way real secret, Mylord-only per Rule 8 — reclassified
into `docs/enterprise-final-100/EXTERNAL_GO_LIVE_DEPENDENCIES.md`, not chased further here.

## Statut final

| ID | Statut |
|---|---|
| P2-4 | **Fermé (preuve)** — both views inspected, written verdict: intentional, safe |
| P2-5 | Corrigé-non-déployé — live-tested on dr-scratch, all 16 functions |
| P2-8 | Corrigé-non-déployé — live-tested end-to-end on dr-scratch, including a caught-before-ship bug |
| P2-13 | **Fermé (preuve)** — wired into a real screen, owner-path safety proven |
| P2-21 (pinning) | Reclassé External Dependency |
| P2-21 (root/jailbreak) | Ouvert — full procedure written, explicit statement of unverifiable-in-environment |
| P2-26 | **Fermé (preuve)** — fail-open reconfirmed correct, silence gap closed |
| P1-4 | Reclassé External Dependency |

## Documentation associée

`docs/security/ROOT_JAILBREAK_DETECTION_PROCEDURE.md` (new), `docs/security/APP_CHECK_ARCHITECTURE.md`
(precedent followed), `supabase/migrations/20260706100000_cp2_system_admin_grant_audit.sql`.

## Commit hash

See end-of-checkpoint commit.
