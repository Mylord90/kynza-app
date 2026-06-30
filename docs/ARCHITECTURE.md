# KYNZA — Architecture Overview

## 1. System Overview

KYNZA is a multi-tenant SaaS for Burundian beauty salons. One Supabase project
serves all tenants; tenant isolation is enforced at the database layer via RLS,
never at the application layer.

```
Flutter App (client)
   │
   │ HTTPS / WebSocket
   ▼
Supabase (Backend-as-a-Service)
   ├── PostgreSQL 15 (primary store, RLS enforced)
   ├── Auth (JWT issuer — GoTrue)
   ├── Storage (media, backups)
   ├── Realtime (WebSocket pub/sub on Postgres changes)
   └── Edge Functions (Deno, business logic requiring service_role)
          │
          ├── Leapa API (mobile money payments)
          └── Firebase FCM (push notifications)
```

## 2. Tech Stack

| Layer | Technology | Version |
|---|---|---|
| Mobile | Flutter | 3.22+ |
| Language | Dart | 3.4+ |
| State management | Riverpod | 2.5+ |
| Navigation | GoRouter | 14+ |
| Data models | Freezed + json_serializable | — |
| Backend | Supabase (Postgres + Auth + Storage + Realtime) | — |
| Edge Functions | Deno (TypeScript) | — |
| Push | Firebase Cloud Messaging | — |
| Local cache | Hive | — |
| Payments | Leapa API | — |
| Charts | fl_chart | 0.68+ |
| PDF | pdf + printing | — |
| QR | mobile_scanner (scan) + qr_flutter (display) | — |

## 3. Flutter Architecture

### 3.1 Directory layout

```
lib/
├── core/
│   ├── constants/         # AppColors, AppTypography, AppSpacing, AppVersion…
│   ├── enums/             # UserRole, BookingStatus…
│   ├── errors/            # AppException
│   ├── models/            # Shared Freezed models (cross-feature)
│   ├── providers/         # auth_providers, connectivity_providers…
│   ├── router/            # app_router.dart, route_names.dart, deep_link_handler.dart
│   ├── services/          # SupabaseService (singleton), CrashReportingService
│   └── utils/             # auth_redirect, validators…
├── features/
│   ├── auth/              # login, register, verify-email, complete-profile
│   ├── booking/           # salon-discovery → service-selection → confirmation
│   ├── dashboard/         # advanced analytics, audit log
│   ├── data_platform/     # backup, document templates (Phase 3)
│   ├── evolution/         # feature-flags, maintenance, version-manager (Phase 4)
│   ├── home_owner/        # Owner dashboard + tab navigator
│   ├── home_manager/      # Manager dashboard
│   ├── home_staff/        # Staff today view
│   ├── home_client/       # Client discovery / bookings / profile
│   ├── loyalty/           # cards, QR, scan
│   ├── marketing/         # campaigns, promotions, referrals
│   ├── notifications/     # FCM, notification list, settings
│   ├── payment/           # Leapa checkout flow
│   ├── permissions/       # RBAC groups + overrides (Phase 1.1)
│   ├── reviews/           # leave review, owner review list
│   ├── salon/             # creation wizard, settings
│   ├── search/            # advanced search (FTS + ILIKE fallback)
│   ├── services/          # services list + CRUD
│   ├── settings/          # salon settings center (Phase 1.4)
│   ├── staff/             # staff list, detail, invitation
│   ├── team/              # commissions (Phase 5)
│   └── …
└── shared/
    └── widgets/           # KynzaButton, KynzaCard, KynzaSpinner, KynzaBadge,
                           # KynzaEmptyState, KynzaErrorState, KynzaSkeleton,
                           # KynzaOfflineBanner, KynzaTextField…
```

### 3.2 Feature module structure

Every feature follows the same four-layer layout:

```
features/<name>/
├── domain/
│   └── repositories/<name>_repository.dart    # abstract interface
├── data/
│   └── repositories/<name>_repository_impl.dart  # Supabase impl
├── application/
│   └── providers/<name>_providers.dart        # Riverpod providers + notifiers
└── presentation/
    ├── screens/
    └── widgets/
```

### 3.3 Provider conventions

- **`FutureProvider`** — read-only async data (list, single record)
- **`FutureProvider.family`** — parametric async data (keyed by salonId, userId…)
- **`AsyncNotifier`** — write operations (create, update, delete); always
  invalidates related `FutureProvider` on success
- **No `@riverpod` codegen** — all providers are hand-written for predictability
- **`autoDispose` default OFF** for global providers that the router needs to read
  synchronously (maintenance, version check); ON everywhere else

### 3.4 UI state machine (R04)

Every data-backed screen implements exactly 5 states:

| State | Widget |
|---|---|
| Loading | `KynzaSkeleton` (height matches real content) |
| Error | `KynzaErrorState` (message + onRetry) |
| Empty | `KynzaEmptyState` (icon + title + subtitle + ctaLabel + onCta — CTA required) |
| Content (< 5 items) | `Column` of widgets |
| Content (≥ 5 items) | `ListView.builder` |

No `CircularProgressIndicator` alone on an empty screen. No dead-ends (R05).

## 4. Database Architecture

### 4.1 Multi-tenancy

Every row in every business table carries `salon_id UUID REFERENCES salons(id)`.
The value is **never trusted from the client** — it is always derived server-side
from `auth.uid()` via the `users` table:

```sql
-- Pattern used in all SECURITY INVOKER RPCs and by the SDK client internally:
SELECT u.salon_id FROM public.users u WHERE u.id = auth.uid() LIMIT 1
```

Client code passes `salonId` as a UI hint only — the actual filter in RLS
policies reads from the JWT.

### 4.2 RLS policy pattern

All policies use exactly one function:

```sql
-- Signature (3rd param optional, defaults NULL = any-salon check)
has_role(p_uid UUID, p_role TEXT, p_salon_id UUID DEFAULT NULL) → BOOLEAN
```

Example READ policy:
```sql
CREATE POLICY "bookings_owner_manager_select"
  ON public.bookings FOR SELECT TO authenticated
  USING (
    has_role(auth.uid(), 'owner',   salon_id) OR
    has_role(auth.uid(), 'manager', salon_id) OR
    has_role(auth.uid(), 'staff',   salon_id)
  );
```

No policy reads `auth.jwt()` or `auth.jwt()->>'app_metadata'` directly —
this was a deliberate architectural decision (see Phase 1.1 notes in AGENT.md).

### 4.3 Soft-delete everywhere

```sql
-- All business tables have:
deleted_at TIMESTAMPTZ DEFAULT NULL

-- All queries filter:
WHERE deleted_at IS NULL

-- Never:
DELETE FROM <table>  -- forbidden by rule R12 + AGENT.md §2
```

### 4.4 Auto-seed pattern

Three features use trigger + backfill for data that must exist per salon:

| Feature | Table | Trigger | Backfill |
|---|---|---|---|
| Settings | `salon_settings` | `trg_auto_salon_settings` ON salons INSERT | Phase 1.4 migration DO block |
| Automation | `automation_workflows` (4 system templates) | `trg_auto_workflows` ON salons INSERT | Phase 2 migration DO block |
| Templates | `document_templates` (3 default types) | `trg_auto_document_templates` ON salons INSERT | Phase 3 migration DO block |

New salons always get their data automatically; existing salons got it via
the backfill DO block in the migration that introduced the feature.

### 4.5 Generated tsvector columns (Phase 3 FTS)

```sql
-- GIN index on trigrams (speeds up ILIKE %query% automatically)
CREATE INDEX idx_salons_name_trgm ON public.salons
  USING GIN (name gin_trgm_ops) WHERE deleted_at IS NULL;

-- Generated column + GIN index for full-text search
ALTER TABLE public.salons ADD COLUMN search_vector TSVECTOR
  GENERATED ALWAYS AS (
    setweight(to_tsvector('simple', coalesce(name, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(slogan, '')), 'B') || …
  ) STORED;
CREATE INDEX idx_salons_search_vector ON public.salons USING GIN (search_vector);
```

Config `'simple'` (not `'french'`) — preserves brand names / proper nouns
without stemming. Important for Burundian salon names that mix French words
and branded compound words.

### 4.6 Materialized view tenant isolation

`mv_daily_revenue` has no RLS (Postgres limitation). Access pattern:

```
service_role → mv_daily_revenue (full data, used by automation update_stats)
authenticated → v_mv_daily_revenue (thin view with inline WHERE salon_id = ...)
```

Same pattern applies to `mv_audit_stats`.

## 5. Edge Functions

All Edge Functions live in `supabase/functions/`. Shared helpers in
`supabase/functions/_shared/`:
- `cors.ts` — CORS headers for browser preflight
- `supabase_admin.ts` — `createClient(service_role_key)` for bypassing RLS

### 5.1 Common pattern

```typescript
serve(async (req) => {
  if (req.method === 'OPTIONS') return cors(req, new Response('ok'));

  // 1. Auth check
  const { data: { user }, error } = await supabase.auth.getUser(jwt);
  if (!user) return json({ error: 'Unauthorized' }, 401);

  // 2. Role check (owner/manager only, etc.)
  const profile = await admin.from('users').select('role, salon_id')
    .eq('id', user.id).single();

  // 3. Business logic using admin client (bypasses RLS)
  // ...

  return cors(req, json(result));
});
```

### 5.2 Function catalog

| Function | Trigger | Auth required | Role required |
|---|---|---|---|
| `create-booking` | Flutter (client checkout) | Yes | client |
| `leapa-webhook` | Leapa (HTTP callback) | No (HMAC signature) | — |
| `mark-no-show` | Flutter (staff action) | Yes | staff / manager / owner |
| `send-notification` | Other Edge Functions | Yes (service_role) | — |
| `validate-qr` | Flutter (owner scan) | Yes | owner / manager / staff |
| `execute-workflow` | Other Edge Functions | Yes (service_role) | — |
| `run-scheduled-actions` | pg_cron (every 5 min) | No (service_role) | — |
| `create-backup` | Flutter (owner action) | Yes | owner / manager |

## 6. Authentication & Authorization Flow

```
User logs in
  └── Supabase Auth issues JWT (uid + role claim "authenticated")
        └── Flutter stores JWT in flutter_secure_storage
              └── Every Supabase REST/RPC call sends JWT as Bearer token
                    └── GoTrue validates JWT
                          └── Postgres enforces RLS using auth.uid()
                                └── has_role(auth.uid(), role, salon_id) checks
                                      public.users table (SECURITY INVOKER)
```

Edge Functions receive the same JWT in the `Authorization` header, call
`supabase.auth.getUser(jwt)` to validate, then switch to an admin client
(`service_role` key) for business logic that must bypass RLS.

## 7. Router Architecture

The single GoRouter instance (`appRouterProvider`) owns all navigation. Key
design decisions:

- **No ShellRoute** — bottom nav is local state per `Home*Screen`. Known debt;
  refactor before Play Store (see DETTE TECHNIQUE in AGENT.md §17).
- **`_RoleGuard`** — wraps every protected route; reads `authNotifierProvider`
  and shows `KynzaFullPageLock` if the current role doesn't match.
- **Loader widgets** — e.g. `_OwnerBackupLoader` resolves `ownerSalonProvider`
  before handing off to the screen. Avoids null-checks inside screens.
- **`_AuthRefreshNotifier`** — subscribes to `authNotifierProvider`,
  `maintenanceStatusProvider`, and `appVersionCheckProvider`; calls
  `notifyListeners()` on any change so the router re-evaluates its `redirect`.
- **Redirect priority chain** (authenticated users):
  1. Force-update gate (highest)
  2. Maintenance gate
  3. Auth-state routing (guest → login, authenticated → home)

## 8. Data Flow — Booking Creation

```
Client taps "Confirmer"
  │
  ├── bookingFlowProvider.notifier.createBooking()
  │     └── SupabaseService.functions.invoke('create-booking', body: {...})
  │           └── create-booking/index.ts
  │                 ├── Validates JWT (Supabase Auth)
  │                 ├── Checks freemium quota (bookings this month)
  │                 ├── Atomic slot lock: BEGIN → SELECT FOR UPDATE → INSERT booking → COMMIT
  │                 ├── Creates Leapa payment intent
  │                 ├── Calls execute-workflow (automation triggers)
  │                 └── Returns { booking_id, payment_url }
  │
  └── Flutter navigates to PaymentScreen(booking)
        └── WebView opens payment_url (Leapa hosted page)
              └── Leapa calls /leapa-webhook on payment success
                    └── leapa-webhook marks booking CONFIRMED_PAID
                          └── Supabase Realtime pushes update to Flutter
                                └── bookingFlowProvider refreshes
```

## 9. Offline Strategy (R03)

- **`ConnectivityService`** — wraps `connectivity_plus`, broadcasts stream
- **`KynzaOfflineBanner`** — shown at top of every scaffold; auto-hides on reconnect
- **Hive** — persists session data and the 15-minute RBAC permission cache
  (`check_permission` results)
- **Sync queue** (conceptual; not yet implemented): new bookings → changed
  statuses → cash payments → notes
- Supabase Realtime reconnects automatically on network restore

## 10. Enterprise Features (Foundation V2)

Added in phases 1–4, all additive — zero breaking changes to existing code:

| Phase | Feature | Key tables/RPCs |
|---|---|---|
| 1.1 | RBAC permission groups | `permission_groups`, `user_permission_overrides`, `check_permission()` |
| 1.2 | Enterprise audit logging | `activity_logs` (extended), `mv_audit_stats`, `AuditLogger` |
| 1.3 | Entity versioning | `entity_versions`, `create_entity_version()`, triggers on services+invoices |
| 1.4 | Salon settings center | `salon_settings` (29 cols), `SettingsHomeScreen` |
| 2 | Automation platform | `automation_workflows/conditions/actions/action_runs`, `execute-workflow`, `run-scheduled-actions` |
| 3 | Data platform | FTS (`search_salon_data`), `mv_daily_revenue`, `backup_jobs`, `document_templates` |
| 4 | Evolution platform | `feature_flags`, `salon_feature_overrides`, `maintenance_windows`, `app_versions`, `evaluate_feature_flag()`, `is_maintenance_active()`, `check_app_version()` |