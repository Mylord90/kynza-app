# KYNZA — API Reference

All RPC functions are callable via Supabase's PostgREST `/rpc/<name>` endpoint
with an `Authorization: Bearer <jwt>` header. Edge Functions are called via the
Supabase Functions URL `https://<ref>.supabase.co/functions/v1/<name>`.

---

## PostgreSQL RPC Functions

### `check_permission(p_resource, p_action) → BOOLEAN`

**Auth:** authenticated  
**Params:** `p_resource TEXT`, `p_action TEXT`  
**Returns:** `BOOLEAN`

Checks whether the calling user has permission for `resource:action`. Resolution
order: user-level override (explicit grant/deny) → group permissions → role
defaults. Results are deterministic for the same `auth.uid()` and can be cached
client-side (KYNZA caches 15 min in Hive).

```dart
final allowed = await SupabaseService.client
    .rpc('check_permission', params: {'p_resource': 'bookings', 'p_action': 'cancel'})
    as bool;
```

---

### `create_entity_version(p_entity_type, p_entity_id, p_data) → VOID`

**Auth:** authenticated  
**Params:** `p_entity_type TEXT`, `p_entity_id UUID`, `p_data JSONB`  
**Returns:** VOID

Stores a snapshot of an entity in `entity_versions`. Called automatically by
triggers on `services` and `invoices`; can be called manually for other entities.
`p_data` is the full JSON row at the time of change.

---

### `search_salon_data(p_query, p_type, p_province, p_limit) → TABLE`

**Auth:** authenticated  
**Params:** `p_query TEXT`, `p_type TEXT DEFAULT NULL`, `p_province TEXT DEFAULT NULL`, `p_limit INT DEFAULT 20`  
**Returns:** `TABLE(id UUID, type TEXT, name TEXT, subtitle TEXT, rank REAL)`

Unified full-text search across salons and services using `search_vector @@ to_tsquery('simple', ...)`.
`type` filter: `'salon'` | `'service'` | `NULL` (both). `province` filter narrows
to salons in a specific province. Results ordered by ts_rank descending.

Fallback behavior in Flutter (`SearchRepositoryImpl`): if the RPC fails or
returns 0 results with service-only filters active, it falls back to direct
`ILIKE '%query%'` queries.

```dart
final results = await SupabaseService.client
    .rpc('search_salon_data', params: {
      'p_query': query, 'p_type': 'salon', 'p_limit': 20
    }) as List<dynamic>;
```

---

### `render_template(p_template_id, p_variables) → TEXT`

**Auth:** authenticated  
**Params:** `p_template_id UUID`, `p_variables JSONB`  
**Returns:** `TEXT`

Renders a `document_templates` record by replacing `{{variable_name}}` placeholders
with values from `p_variables`. Missing keys are left as-is. System templates
(`is_system = TRUE`) are read-only — they can be rendered but not modified via RLS.

```dart
final html = await SupabaseService.client
    .rpc('render_template', params: {
      'p_template_id': templateId,
      'p_variables': {'client_name': 'Alice', 'amount': '12 000 FBu', ...}
    }) as String;
```

---

### `create_default_document_templates(p_salon_id) → VOID`

**Auth:** service_role only (called by trigger `trg_auto_document_templates`)  
**Params:** `p_salon_id UUID`  
**Returns:** VOID

Seeds the 3 default templates (invoice, receipt, monthly_report) for a new salon.
Not called directly by Flutter. Called by the INSERT trigger on `salons` and
by the backfill DO block in the Phase 3 migration.

---

### `evaluate_feature_flag(p_key) → BOOLEAN`

**Auth:** authenticated  
**Params:** `p_key TEXT`  
**Returns:** `BOOLEAN`

Evaluates whether the calling user's salon has access to feature flag `p_key`.
Resolution order:
1. Salon override (`salon_feature_overrides`) → return override value
2. Global flag disabled → `false`
3. `rollout_percentage ≥ 100` → `true`
4. Deterministic bucket: `md5(salon_id || key) mod 100 < rollout_percentage`

Returns `false` when `salon_id IS NULL` (service_role context, unauthenticated).

```dart
final enabled = await SupabaseService.client
    .rpc('evaluate_feature_flag', params: {'p_key': 'instant_booking'})
    as bool? ?? false;
```

---

### `is_maintenance_active() → TABLE`

**Auth:** authenticated  
**Returns:** `TABLE(is_active BOOLEAN, title TEXT, message TEXT, ends_at TIMESTAMPTZ)`

Always returns exactly 1 row. Checks for active maintenance windows where
`now() BETWEEN starts_at AND ends_at` AND (`affects_all = true` OR the calling
user's `salon_id = ANY(affected_salon_ids)`). Returns `{false, NULL, NULL, NULL}`
when no active window exists.

Called by `MaintenanceRepositoryImpl` after an auth check. If `auth.uid()` is
NULL (not yet logged in), the repository returns `null` without calling the RPC.

```dart
final rows = await SupabaseService.client.rpc('is_maintenance_active')
    as List<dynamic>;
// rows.first = {'is_active': false, 'title': null, 'message': null, 'ends_at': null}
```

---

### `check_app_version(p_platform, p_version_code) → TABLE`

**Auth:** authenticated  
**Params:** `p_platform TEXT` (`'android'` | `'ios'`), `p_version_code INT`  
**Returns:** `TABLE(update_required BOOLEAN, update_recommended BOOLEAN, latest_version_name TEXT, latest_version_code INT, message TEXT)`

Compares `p_version_code` against the latest published version for the platform.
- `update_required = true` if `p_version_code < MIN(version_code WHERE is_minimum_required)`
- `update_recommended = true` if `p_version_code < MAX(version_code)`

Called by `VersionRepositoryImpl` with `kAppVersionCode` and `kAppPlatform`
from `lib/core/constants/app_version.dart`.

```dart
final rows = await SupabaseService.client.rpc('check_app_version',
    params: {'p_platform': kAppPlatform, 'p_version_code': kAppVersionCode})
    as List<dynamic>;
```

---

## Edge Functions

Base URL: `https://hhdkjfpgaklhrhfoxlhj.supabase.co/functions/v1/`

All functions return `Content-Type: application/json`. CORS is handled by the
shared `cors.ts` helper — `OPTIONS` requests return 200.

---

### `POST /create-booking`

**Auth:** Bearer JWT (authenticated client)  
**Role required:** client

Creates a booking with atomic slot locking. Enforces freemium quota (20
bookings/month on free plan). Creates a Leapa payment intent if the service
requires payment.

**Request body:**
```json
{
  "salon_id": "uuid",
  "service_id": "uuid",
  "practitioner_id": "uuid",
  "start_time": "2026-07-01T10:00:00Z",
  "notes": "optional client notes"
}
```

**Response (200):**
```json
{
  "booking_id": "uuid",
  "payment_url": "https://leapa.bi/pay/...",
  "status": "pending_payment"
}
```

**Errors:**
- `409` — slot already taken (concurrent booking)
- `402` — freemium quota exceeded
- `401` — unauthenticated

---

### `POST /leapa-webhook`

**Auth:** HMAC-SHA256 signature on `X-Leapa-Signature` header  
**Role required:** none (called by Leapa)

Handles Leapa payment callbacks. On `payment.success`: marks booking
`CONFIRMED_PAID`, triggers `booking.created` automation, sends FCM push via
`send-notification`. On `payment.failed`: marks booking `CANCELLED`,
releases the slot.

**Request body:** Leapa event payload (webhook format defined by Leapa API)

---

### `POST /mark-no-show`

**Auth:** Bearer JWT (authenticated)  
**Role required:** staff / manager / owner

Marks a booking as `no_show`, decrements the client's `reliability_score`,
and checks if 3+ no-shows triggers `deposit_required = true`.

**Request body:**
```json
{ "booking_id": "uuid" }
```

**Response (200):**
```json
{ "success": true, "reliability_score": 2, "deposit_required": false }
```

---

### `POST /send-notification`

**Auth:** service_role (called by other Edge Functions, not Flutter directly)  
**Role required:** none

Sends an FCM push notification to a device.

**Request body:**
```json
{
  "user_id": "uuid",
  "title": "string",
  "body": "string",
  "data": { "route": "/bookings/uuid" }
}
```

---

### `POST /validate-qr`

**Auth:** Bearer JWT (authenticated)  
**Role required:** owner / manager / staff

Validates a loyalty QR code scan. Awards a stamp, checks if the card is full
(triggers reward), and updates `reliability_score` (positive signal).

**Request body:**
```json
{
  "loyalty_card_id": "uuid",
  "qr_token": "string"
}
```

**Response (200):**
```json
{
  "stamps_added": 1,
  "current_stamps": 8,
  "max_stamps": 10,
  "reward_triggered": false
}
```

---

### `POST /execute-workflow`

**Auth:** service_role (called by `create-booking`, `leapa-webhook`, etc.)  
**Role required:** none

Evaluates automation workflows for a given trigger event. For each matching
workflow, evaluates conditions, then either executes immediate actions or
enqueues delayed ones in `automation_action_runs`.

**Request body:**
```json
{
  "salon_id": "uuid",
  "trigger_type": "booking.created",
  "context": { "booking_id": "uuid", "client_name": "Alice", "service_name": "Coupe" }
}
```

---

### `POST /run-scheduled-actions`

**Auth:** service_role (called by pg_cron every 5 min)  
**Role required:** none

Processes pending `automation_action_runs` where `scheduled_for <= now()`.
Executes actions (send_sms, send_whatsapp, send_push, assign_badge, apply_discount).
On failure: exponential backoff (2/4/8 min), max 3 attempts, then `status = failed`.

---

### `POST /create-backup`

**Auth:** Bearer JWT (authenticated)  
**Role required:** owner / manager

Creates a full data backup for the salon. Limits to 1 backup per 6 hours
(enforced via `backup_jobs` table). Collects 90 days of transactional data
(bookings, transactions, reviews) + full reference data (services, staff, settings)
→ uploads as JSON to `kynza-backups` Supabase Storage (private bucket).

**Response (200):**
```json
{
  "job_id": "uuid",
  "status": "completed",
  "storage_path": "uuid/2026-06-30T10:00:00Z.json",
  "file_size_bytes": 145230
}
```

**Errors:**
- `429` — backup too recent (< 6 hours since last completed backup)

---

## Key Database Tables (reference)

| Table | Primary key | Tenant key | Soft-delete | Notes |
|---|---|---|---|---|
| `salons` | `id` | `id` (is itself) | `deleted_at` | Root tenant entity |
| `users` | `id` | `salon_id` | `deleted_at` | Mirrors auth.users |
| `services` | `id` | `salon_id` | `deleted_at` | Versioned via trigger |
| `bookings` | `id` | `salon_id` | `deleted_at` | State machine |
| `transactions` | `id` | `salon_id` | — | Payment ledger |
| `loyalty_cards` | `id` | `salon_id` | `deleted_at` | Per-client |
| `activity_logs` | `id` | `salon_id` | — | Append-only audit log |
| `entity_versions` | `id` | `salon_id` | — | Append-only snapshots |
| `automation_workflows` | `id` | `salon_id` | `deleted_at` | 4 system + custom |
| `backup_jobs` | `id` | `salon_id` | — | 1/6h limit enforced |
| `document_templates` | `id` | `salon_id` | — | 3 system + custom |
| `feature_flags` | `id` | — (global) | — | Service_role write only |
| `salon_feature_overrides` | `id` | `salon_id` | — | Per-salon flag toggles |
| `maintenance_windows` | `id` | — (global) | — | Service_role write only |
| `app_versions` | `id` | — (global) | — | Service_role write only |