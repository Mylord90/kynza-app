# KYNZA — Role-Based Workflows

> Extracted directly from `lib/core/router/app_router.dart` (69 routes, full redirect chain),
> `lib/core/router/route_names.dart`, `lib/core/permissions/*`, and `lib/features/auth/` —
> verified 2026-07-03, not reconstructed from the original spec's assumed route list. Every
> screen named below has a corresponding `GoRoute` or is explicitly marked as in-flow-only
> (reached via `Navigator.push`, no dedicated route).

## 1. Objectifs

Give a developer the exact navigable graph per role — including the two real gaps found during
extraction (the Manager home is a UI stub; `PermissionGuard` exists but is wired into zero
screens) — so no one builds against an assumed role/permission model that doesn't match the code.

## 2. Architecture

### 2.1 Router shape

**No `ShellRoute` exists** (confirmed, matches the tracked tech-debt item in
`docs/architecture` history) — it's a flat list of top-level `GoRoute`s. Each of the four real
home screens (`HomeOwnerScreen`, `HomeManagerScreen`, `HomeStaffScreen`, `HomeClientScreen`) is
itself the bottom-nav container via `KynzaBottomNav`, managing its own `_tabIndex` local state.
Every route is wrapped in a shared fade+slide `CustomTransitionPage` helper (`_fadeRoute()`).

### 2.2 Guard vocabulary

- **`_RoleGuard(role: X, child:)`** / **`_RoleGuard.anyOf(roles: {X,Y}, child:)`** — watches
  `authNotifierProvider`; if the authenticated user's role isn't in the allowed set, renders
  `KynzaFullPageLock(requiredRole:)` instead of the screen.
- **`_Owner*Loader` / `_Staff*Loader` widgets** (e.g. `_OwnerBackupLoader`, `_StaffOwnHoursLoader`)
  — resolve a required provider (`ownerSalonProvider`, `myStaffProfileProvider`) first, showing
  `KynzaLoaderInline` while pending and an inline "not found → back to home" control on
  null/error, **before** handing off to the real screen. These sit inside the role guard, not
  instead of it.
- **`_OwnerOnboardingGuard`** (on `ownerSalonCreate` only) — blocks re-entry to the salon creation
  wizard once `ownerSalonProvider` resolves non-null ("Vous avez déjà un salon").

### 2.3 Redirect priority chain (`app_router.dart`, evaluated on every navigation)

1. **Deep-link rewrite** — if `state.uri.host` is non-empty (true only for `com.kynza.app://…`
   links), `DeepLinkHandler.parseRoute(uri)` rewrites the target path before anything else runs.
2. **Auth state not yet resolved** → no redirect (`null`).
3. **`unauthenticated`** → `login`/`register`/`forgotPassword`/`/` (splash) and the two
   whitelisted deep-link routes (`acceptInvitation`, `acceptReferral`) pass through; everything
   else → `login`.
4. **`authenticated(user)`**:
   a. On a guest route (`login`/`register`/`forgotPassword`) → role-based home via
      `redirectAfterAuth(user)`.
   b. **Force-update gate** — `appVersionCheckProvider.updateRequired == true` → `forceUpdate`
      (unless already there).
   c. **Maintenance gate** — `maintenanceStatusProvider.isActive == true` → `maintenance`
      (unless already there; `MaintenanceScreen` polls every 30s and invalidates the provider
      once the window ends).
   d. Otherwise no redirect.
5. **`emailNotVerified`** → forces `verifyEmail` (except `verifyEmail`/`callback` themselves).
6. **`profileIncomplete`** → forces `completeProfile` (except `completeProfile`/`callback`).

The splash screen is deliberately exempt from the `unauthenticated` redirect — it owns its own
minimum-display-time transition.

### 2.4 Deep links

`DeepLinkHandler` recognizes exactly **4** hosts under the `com.kynza.app://` scheme:
`accept-invitation`, `accept-referral`, `salon` (→ `clientSalonDetailPath`), `booking` (→
`clientPaymentPath`). Only the first two are whitelisted to bypass the login-required redirect;
`salon`/`booking` links still force a login first, with **no pending-link stash** for those two
(only invitation/referral tokens are queued). **No ProxiPay or loyalty-QR deep link host is
registered** — those flows are in-app-only navigation, never external links.

Pending-token queueing (confirmed against `SessionService`): a logged-out tap on an invitation or
referral link stores the token in Hive (`savePendingInvitationToken`/`savePendingReferralToken`),
routes to `register`, and `resolvePostAuthRoute()` (checked from `LoginScreen`, `RegisterScreen`,
`CompleteProfileScreen`) consumes it after auth completes — invitation takes priority over
referral if both were somehow stashed. Both final hops (`accept-invitation` →
`accept-invitation` Edge Function → force-nav `homeStaff`; `accept-referral` → `claim-referral`
Edge Function → force-nav `homeClient`) **bypass** the normal `redirectAfterAuth` role switch.

### 2.5 Permission system — built but not wired

`PermissionGuard` (`lib/core/permissions/permission_guard.dart`) is fully implemented — it watches
`permissionProvider((feature, action, resource))`, renders `child` only on `data: true`, and
`fallback ?? SizedBox.shrink()` otherwise. **It is referenced nowhere outside its own definition
file** — zero screens under `lib/features/` actually use it. All current permission enforcement
happens at the **route level** (`_RoleGuard`, coarse role check) and at the **database level**
(RLS). Fine-grained per-action permission checks (the whole point of `permission_definitions` /
`permission_groups`) exist as infrastructure only. This is a real gap, not a design choice —
tracked in Part 14.

`check_permission()` is called from `PermissionService.hasPermission()` via
`_client.rpc('check_permission', ...)`, fails closed on any exception, and is cached in Hive
(`permission_cache` box) for **15 minutes** (matches the server-side
`user_effective_permissions_cache.expires_at` default). Expiry is a hard cutoff, not
stale-while-revalidate — a cache miss triggers a synchronous RPC round trip before the UI
resolves, shown via `PermissionGuard`'s `loading:` branch (which, again, no screen currently
uses).

**23 seeded `permission_definitions` rows** (not 22 as referenced in the original spec — recount
verified directly against the migration's `INSERT` statement, `20260629100000_rbac_enterprise.sql`
lines 41–63): `bookings.{view.all, view.own, create.all, edit.all, cancel.all, mark_no_show.all}`,
`staff.{view.all, manage.all, view_commissions.own, view_commissions.all}`,
`analytics.{view.basic, view.advanced, export.all}`, `billing.{view.all, manage.all}`,
`loyalty.{view.all, stamp.all}`, `marketing.{view.all, manage.all}`,
`reviews.{view.all, respond.all}`, `settings.{view.all, manage.all}`. Resolution order:
owner (always `TRUE`) → `user_permission_overrides` → `bool_or` across the user's
`permission_groups` → default `FALSE`.

### 2.6 Auth providers

Email/password and **Google** are fully wired end-to-end (`AuthNotifier` →
`AuthRepositoryImpl` → `AuthSupabaseDatasource` → `supabase.auth.signInWithOAuth`/
`signInWithPassword`). **Facebook and Apple sign-in are both stubs** —
`signInWithFacebook()`/`signInWithApple()` throw `UnimplementedError('... arrives in V2')`, and
their buttons render with `onPressed: null` behind a "coming soon" tooltip on both
`login_screen.dart` and `register_screen.dart`. Role is chosen client-side on
`CompleteProfileScreen` (a direct `UPDATE users SET role=...` from Flutter, not a server
function) for self-registered users; staff-via-invitation and client-via-referral get their role
set server-side by the respective Edge Function instead, bypassing this screen.

## 3. Role Workflows

### 3.1 CLIENT

Diagram: [`docs/diagrams/workflow-client.mermaid`](diagrams/workflow-client.mermaid).

**Entry points**: `/auth/login` → email/Google → `complete-profile` (role=client) → `/client/home`.
Also reachable directly via a whitelisted `accept-referral` deep link while logged out.

| Screen | Route | Purpose | Primary CTA | Guard | Offline |
|---|---|---|---|---|---|
| Home tab | `/client/home` (tab 0) | Dashboard/shortcuts | Discover salons | `_RoleGuard(client)` | Cached-last-fetch, standard 5-state pattern |
| Discover | `/client/discover` (tab 1) | Search/filter salons | Open a salon | same | FTS search requires network; no offline cache of the salon catalog today |
| Salon detail | `/client/salon/:id` | Salon profile, services, staff | "Réserver" | same | Cached if previously viewed via `.stream()` last emission; otherwise blocked |
| Booking entry | `/client/booking` | Resume or start booking flow | — | same | **Booking creation requires network** — no offline queue exists (§2.5 of `ARCHITECTURE_GLOBAL.md`) |
| Booking confirm | `/client/booking/confirm` | **No `GoRoute` exists** — reached only via in-flow `Navigator.push`, not `context.go` | Confirm | same (inherited) | n/a |
| Payment | `/client/payment/:id` | Mobile Money or ProxiPay checkout | Pay | same | Mobile Money strictly requires network (non-custodial, R01) — no offline fallback except cash-in-person via ProxiPay |
| ProxiPay scan | `/client/proxipay/scan` | Scan staff's in-person QR | Confirm payment | same | Requires network for `proxipay-confirm` |
| My bookings | `/client/bookings` (tab 2) | Booking history | Leave review | same | Realtime `.stream()` by `client_id`, cached last emission offline |
| Leave review | `/client/review/:bookingId` | Rate a completed booking | Submit | same | Requires network — no offline review draft queue exists despite being named as a target in the offline skill spec |
| My loyalty | `/client/loyalty` (tab 3) | Stamp cards | Show QR | same | Realtime `.stream()` by `client_id` |
| Loyalty QR | `/client/loyalty/qr/:cardId` | Display scannable QR for staff | — | same | QR token generation requires network |
| Profile | `/client/profile` (tab 4) | Account settings | Edit profile | same | Cached in `kynza_prefs` (language, confidential mode) |
| Search | `/search` | Advanced filtered search | Open result | same | Same as Discover |

**Edge cases**: expired session → redirect chain forces `login` on next navigation (no silent
retry); concurrent booking conflict → `create-booking` returns `409 slot_taken`, client
re-renders the slot picker (not a generic error); double payment attempt → prevented by
`idempotency_key` (1-minute window) plus the "disable button on first tap" UI convention.

### 3.2 OWNER

Diagram: [`docs/diagrams/workflow-owner.mermaid`](diagrams/workflow-owner.mermaid).

**Entry points**: `/auth/login` → `complete-profile` (role=owner) → `_OwnerOnboardingGuard` →
`/owner/salon/create` (first time only) → `/owner/dashboard`.

All 5 home tabs are implemented (Calendrier, 📊 Dashboard, Clients, Marketing, Profil). Full
route list (32 owner-guarded routes) is in §2.1's table and the diagram — not repeated
screen-by-screen here to avoid duplicating the diagram; notable groups:

- **Salon & team**: `services`, `staff`/`team`, `team/:staffId`, `team/commissions`,
  `availability` + 4 sub-routes.
- **Marketing & growth**: `marketing` + `clients`/`promotions`/`loyalty` sub-routes, `share`,
  `reviews`, `loyalty/scan` (shared with manager/staff).
- **Analytics & ops**: `analytics` + `clients`/`team`/`forecast` sub-routes, `audit-logs`,
  `permissions` + `:groupId`, `settings`, `automation`, `backup`, `templates`, `feature-flags`.
- **Billing**: `subscription` → `create-manual-invoice` Edge Function → `billing` →
  `billing/invoices`; marking paid calls RPC `mark_invoice_paid` **directly from Flutter**
  (same pattern as `evaluate_feature_flag`) — `billing/success` confirms.
- **ProxiPay**: `owner/proxipay/:bookingId` (shared guard `anyOf({owner,manager,staff})`).

**Permission gates**: route-level only (`_RoleGuard(owner)` exact match for the analytics/audit/
settings/automation/backup/templates/flags/billing group — manager has **no** access to any of
these). Fine-grained `permission_definitions`-based gating (e.g. limiting a specific manager to
`analytics.view.basic` but not `.advanced`) is **not enforced anywhere in the UI** today (§2.5).

**Edge cases**: revoked permission mid-session — since `PermissionGuard` isn't wired in, a role
downgrade only takes effect on the next `_RoleGuard` route-level check (i.e. next full
navigation), not live within an already-open screen; `create-backup` cooldown (max 1/6h) surfaces
as a `429 too_soon` error state, not silently retried.

### 3.3 MANAGER

Diagram: [`docs/diagrams/workflow-manager.mermaid`](diagrams/workflow-manager.mermaid).

**Entry point**: `/manager/dashboard` (`_RoleGuard(manager)`).

**Known gap, verified in code**: `HomeManagerScreen` renders the **same 5-tab `KynzaBottomNav`**
as the owner (identical icons/labels: Calendrier, Dashboard, Clients, Marketing, Profil), but
every tab body currently renders the **same static `KynzaEmptyState` placeholder** regardless of
which tab is selected — none of the 5 tab bodies are actually implemented for the manager shell.
This is a real, verified stub, not a documentation gap — flagged as tech debt in Part 14.

Manager **does** get real access to shared `anyOf({owner, manager})`/`anyOf({owner, manager,
staff})` routes: `services`, `availability` (+ sub-routes), `marketing` (+ sub-routes),
`reviews`, `loyalty/scan`, `proxipay/:bookingId`. Manager is explicitly **excluded** from the
owner-exact-match routes: `staff`/`team`/`commissions`, `analytics`, `audit-logs`,
`permissions`, `settings`, `automation`, `backup`, `templates`, `feature-flags`,
`subscription`/`billing`, `salon/create`.

**Edge cases**: a manager navigating to any owner-only route (e.g. by manually editing a deep
link or a stale bookmark) hits `_RoleGuard(owner)` and sees `KynzaFullPageLock`, not a 404 — same
behavior as any other role mismatch.

### 3.4 STAFF

Diagram: [`docs/diagrams/workflow-staff.mermaid`](diagrams/workflow-staff.mermaid).

**Entry point**: exclusively via invitation — `staff_profiles.invitation_token` deep link or
in-app share → `accept-invitation` Edge Function (sets `role=staff` server-side) → force-navigate
to `/staff/today`, bypassing the normal role-based redirect entirely. There is no self-registration
path to the staff role (`CompleteProfileScreen`'s picker doesn't offer "invited by a salon" —
only client/staff/owner as if self-selecting, but a staff invite always supersedes that screen).

4-tab home (`HomeStaffScreen`): Aujourd'hui, Agenda, Mes clients, Performance.

| Screen | Route | Purpose | Primary CTA | Offline |
|---|---|---|---|---|
| Aujourd'hui | tab 0 | Today's bookings | Mark completed / no-show | Realtime `.stream()` by `practitioner_id`, cached last emission |
| Agenda | tab 1 | Full schedule | Open booking | same |
| Mes clients | tab 2 | Assigned clients | — | same |
| Performance | tab 3 / `/staff/performance` | Own commission/ranking | — | Requires network for `staff_commissions` read |
| Own availability | `/staff/availability` | Self-manage hours (own profile only, **never** a `:staffId` path param, unlike the owner's equivalent route) | Save | Requires network |
| ProxiPay | `/owner/proxipay/:bookingId` (shared) | Display/confirm in-person payment | — | Requires network |
| Loyalty scan | `/owner/loyalty/scan` (shared) | Stamp/redeem client cards directly | Scan | Requires network; RLS allows staff direct write on `loyalty_cards` |

**Edge cases**: `mark-no-show` is **not idempotent** (no unique guard, re-calling re-decrements
the client's `reliability_score`) — the UI must disable the action after first tap, not rely on
server dedup; commission calculation (`calculate-commission`) is best-effort/non-blocking after
marking a booking completed, so a staff member should never see it as a blocking step.

### 3.5 CLIENT_SUPPORT

Diagram: [`docs/diagrams/workflow-client_support.mermaid`](diagrams/workflow-client_support.mermaid).

**This role does not exist in the codebase.** Verified absent from all four places a role must
appear to be real: `lib/core/enums/user_role.dart` (`enum UserRole { owner, manager, staff,
client }` — exactly 4 values), every `_RoleGuard`/`_RoleGuard.anyOf` call site in
`app_router.dart`, the `permission_groups.base_role` CHECK constraint (same 4 values), and a
repo-wide case-insensitive grep for `client_support`/`clientSupport`/`CLIENT_SUPPORT` (zero
matches in source or migrations). Per the hard rule against inventing routes/roles, this document
does not describe a CLIENT_SUPPORT journey — the diagram instead documents what implementing one
would require (new enum value + CHECK constraint updates, new guarded routes, new RLS policies,
new `permission_definitions` rows scoped to read-only/no-financial-mutation access per the
original brief's intent). This is scoped out of the current build, not silently dropped —
tracked explicitly in Part 14 and in the final expansion report.

## 4. Structure & Conventions

Route naming: `RouteNames` static constants in `lib/core/router/route_names.dart`, grouped by the
phase that introduced them (comments like `// Phase 5 — Team Management + Commissions`). Path
convention: `/owner/...`, `/manager/...`, `/staff/...`, `/client/...` prefix mirrors the role
guard, with a handful of unprefixed shared/global routes (`/notifications`, `/search`,
`/maintenance`, `/force-update`, `/accept-invitation`, `/accept-referral`).

## 5. Contraintes & Edge Cases

Covered inline per role in §3. Cross-cutting: session expiry is handled entirely by the redirect
chain re-running on next navigation (§2.3) — there is no proactive session-expiry push to an
already-open screen.

## 6. Sécurité

Route-level guards (`_RoleGuard`) are the primary UI-layer enforcement; the real security
boundary is RLS (see `docs/SECURITY.md`, `docs/DATABASE_ARCHITECTURE.md`). The permission-groups/
`check_permission()` system exists at the database layer regardless of `PermissionGuard` being
unwired in the UI — a determined client bypassing the Flutter UI could not gain unauthorized
access, since RLS and Edge Function role checks are independent of the Flutter-side gate. The gap
in §2.5 is a UX/product-completeness gap (fine-grained permission groups don't yet visibly change
what a manager can do beyond the coarse role split), not a security hole.

## 7. Performance

No route-specific performance targets beyond the general ones in Part 13
(`docs/PERFORMANCE_TARGETS.md`, Phase E).

## 8. Stratégie de tests

No route/workflow-level integration tests currently exist verifying the redirect chain or
per-role route access end-to-end. Recommended (not yet implemented): a `go_router` test harness
asserting each `_RoleGuard`/`_RoleGuard.anyOf` combination redirects correctly for every role,
and a regression test for the manager-home-is-a-stub gap so a future implementation is
intentional, not silently reverted.

## 9. Documentation associée

- `docs/ARCHITECTURE.md` §7 (Router Architecture) — condensed version, cross-linked not duplicated.
- `docs/ARCHITECTURE_GLOBAL.md` §2.7 + `docs/diagrams/security-diagram.mermaid` — JWT/RLS boundary.
- `docs/SECURITY.md` — `has_role()`, RLS policy patterns.
- `docs/DATABASE_ARCHITECTURE.md` §3.1 — `permission_definitions`/`permission_groups` schema.
- `docs/PRODUCTION_CHECKLIST.md` — manager-stub and `PermissionGuard`-unwired gaps appended there (Part 14).

## 10. Critères d'acceptation

- [x] Every screen referenced exists in the current route tree — cross-checked against
  `app_router.dart` directly, including the one route-name-with-no-GoRoute exception
  (`clientBookingConfirm`), called out rather than hidden.
- [x] Every permission gate referenced maps to a real `_RoleGuard` call or an entry in
  `permission_definitions` — no invented gate.
- [x] Offline behavior specified for every mutating action (booking, payment, review, no-show,
  commission) — consistently "requires network," matching the Phase A finding that the offline
  outbox pattern isn't built yet.
- [x] CLIENT_SUPPORT's non-existence is documented rather than fabricated.

## 11. Livrables

- `docs/WORKFLOWS.md` (this file)
- `docs/diagrams/workflow-client.mermaid`
- `docs/diagrams/workflow-owner.mermaid`
- `docs/diagrams/workflow-manager.mermaid`
- `docs/diagrams/workflow-staff.mermaid`
- `docs/diagrams/workflow-client_support.mermaid`
