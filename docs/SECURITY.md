# KYNZA — Security Model

## 1. Core principles

1. **Tenant isolation at the database layer** — RLS enforced on every table,
   never skipped, never conditionally disabled.
2. **`has_role()` is the only RLS mechanism** — no policy reads `auth.jwt()`
   directly or joins `auth.users`. All role checks go through `public.users`.
3. **`salon_id` always derived server-side** — client-supplied `salon_id` is
   never trusted; it is re-derived from `auth.uid()` → `public.users.salon_id`.
4. **Soft-delete only** — no `DELETE` SQL on business data. `deleted_at` column.
5. **Service_role key never in Flutter code** — only in Edge Function env vars
   and Supabase Vault.

---

## 2. The `has_role()` function

```sql
CREATE OR REPLACE FUNCTION public.has_role(
  p_uid      UUID,
  p_role     TEXT,
  p_salon_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY INVOKER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id         = p_uid
      AND u.role       = p_role
      AND u.deleted_at IS NULL
      AND (p_salon_id IS NULL OR u.salon_id = p_salon_id)
  );
$$;
```

Key properties:
- **SECURITY INVOKER** — runs with the caller's privileges; cannot be tricked
  into reading data the caller's RLS blocks.
- **STABLE** — Postgres can cache the result within a single statement
  (important for performance on large scans).
- **3rd argument optional** — `has_role(uid, 'owner')` checks any salon;
  `has_role(uid, 'owner', salon_id)` checks only that salon.
- **`deleted_at IS NULL`** — soft-deleted users cannot authenticate any role.

---

## 3. RLS policy patterns

### Read policy (most tables)
```sql
CREATE POLICY "bookings_select"
  ON public.bookings FOR SELECT TO authenticated
  USING (
    has_role(auth.uid(), 'owner',   salon_id) OR
    has_role(auth.uid(), 'manager', salon_id) OR
    has_role(auth.uid(), 'staff',   salon_id)
  );
```

### Write policy (owner + manager only)
```sql
CREATE POLICY "services_insert"
  ON public.services FOR INSERT TO authenticated
  WITH CHECK (
    has_role(auth.uid(), 'owner',   salon_id) OR
    has_role(auth.uid(), 'manager', salon_id)
  );
```

### Owner-only policy
```sql
CREATE POLICY "feature_overrides_owner_all"
  ON public.salon_feature_overrides FOR ALL TO authenticated
  USING     (has_role(auth.uid(), 'owner', salon_id))
  WITH CHECK (has_role(auth.uid(), 'owner', salon_id));
```

### Client policy (own data only)
```sql
CREATE POLICY "bookings_client_select"
  ON public.bookings FOR SELECT TO authenticated
  USING (
    client_id = auth.uid() AND
    has_role(auth.uid(), 'client', salon_id)
  );
```

---

## 4. Permission resolution chain

For `check_permission(p_resource, p_action)`:

```
1. User-level override (user_permission_overrides)
     → is_granted = true  → ALLOW
     → is_granted = false → DENY

2. Permission group (users.permission_group_id → permission_groups.permissions JSONB)
     → key "resource:action" = true  → ALLOW
     → key "resource:action" = false → DENY

3. Role default
     → role_defaults JSONB field on the permission_group
     → falls through to hard-coded role defaults if no group

4. Default = DENY
```

Cached in Hive for 15 minutes per `(uid, resource, action)` triple. Cache is
invalidated on logout and on explicit `PermissionNotifier.refresh()`.

---

## 5. Edge Function auth pattern

Every Edge Function that requires authentication:

```typescript
// 1. Extract JWT from Authorization header
const jwt = req.headers.get('Authorization')?.replace('Bearer ', '');
if (!jwt) return json({ error: 'Missing token' }, 401);

// 2. Validate with Supabase (hits GoTrue, not Postgres)
const { data: { user }, error } = await supabase.auth.getUser(jwt);
if (error || !user) return json({ error: 'Unauthorized' }, 401);

// 3. Load role from public.users (via admin client to bypass RLS)
const { data: profile } = await admin
    .from('users').select('role, salon_id').eq('id', user.id).single();
if (!profile) return json({ error: 'Profile not found' }, 403);

// 4. Role check
if (!['owner', 'manager'].includes(profile.role))
    return json({ error: 'Forbidden' }, 403);

// 5. All subsequent operations use `admin` (service_role) client
```

---

## 6. Freemium security

The freemium quota (20 bookings/month for free plan) is enforced in the
`create-booking` Edge Function, not in Flutter. The Flutter UI shows the
progress bar but cannot bypass the check.

```typescript
// In create-booking:
const { count } = await admin
    .from('bookings')
    .select('id', { count: 'exact', head: true })
    .eq('salon_id', salonId)
    .gte('created_at', startOfMonth);

if (plan === 'free' && count >= 20) {
    return json({ error: 'Quota exceeded', code: 'FREEMIUM_LIMIT' }, 402);
}
```

This protects against:
- Modified APK bypassing quota check
- Direct API calls skipping Flutter validation

---

## 7. Leapa webhook authentication

No JWT — Leapa calls the webhook from their servers. Authentication uses
HMAC-SHA256 signature:

```typescript
const signature = req.headers.get('X-Leapa-Signature');
const payload   = await req.text();
const expected  = hmacSha256(Deno.env.get('LEAPA_WEBHOOK_SECRET'), payload);
if (signature !== expected) return json({ error: 'Invalid signature' }, 401);
```

`LEAPA_WEBHOOK_SECRET` is stored in Supabase Vault, injected at function
invocation time as an environment variable.

---

## 8. Secrets management

| Secret | Storage | Access pattern |
|---|---|---|
| `LEAPA_API_KEY` | Supabase Vault | Edge Function env var at runtime (`_shared/leapa.ts`) |
| `LEAPA_BASE_URL` | Supabase Vault (not secret-sensitive, env-configurable) | Edge Function env var at runtime (`_shared/leapa.ts`) |
| `LEAPA_WEBHOOK_SECRET` | Supabase Vault | Edge Function env var at runtime (`leapa-webhook/index.ts`) |
| `FCM_SERVICE_ACCOUNT_JSON` | Supabase Vault | Edge Function env var at runtime (`_shared/fcm.ts`) |
| `FCM_PROJECT_ID` | Supabase Vault | Edge Function env var at runtime (`_shared/fcm.ts`) |
| `WHATSAPP_TOKEN` | Supabase Vault | Edge Function env var at runtime (`_shared/whatsapp.ts`) |
| `WHATSAPP_PHONE_NUMBER_ID` | Supabase Vault | Edge Function env var at runtime (`_shared/whatsapp.ts`) |
| Supabase `service_role` key | Supabase Dashboard / CI env | Never in Flutter, never committed |
| Supabase `anon` key | `lib/core/services/supabase_service.dart` | Public; safe (RLS enforces all access) |

> Corrected 2026-07-03 (Phase 5 of the Enterprise Hardening pass) — this table previously named
> `LEAPA_SECRET`, `FCM_KEY`, and `WA_TOKEN`, none of which match the actual `Deno.env.get(...)`
> calls in the Edge Function source (verified directly, not assumed). See
> `docs/security/SECURITY_AUDIT_V2.md` for the full secrets audit and rotation procedure.

The `anon` key is intentionally public — it identifies the project but grants
no access without a valid JWT. RLS + `has_role()` are the actual security layer.

---

## 9. Role immutability (critical RLS gotcha)

The `users.role` column **cannot be changed via the authenticated client**.
Only service_role can update it. This prevents privilege escalation:

```sql
CREATE POLICY "users_no_role_change"
  ON public.users FOR UPDATE TO authenticated
  WITH CHECK (role = OLD.role);  -- role must stay the same
```

This is the "role-immutability RLS gotcha" noted in
`memory/project_phase1_foundation.md` — it was identified during Phase 1.1 and
preserved in every subsequent migration that touches `public.users`.

---

## 10. Materialized view exposure

Postgres materialized views (`mv_daily_revenue`, `mv_audit_stats`) do not support
RLS. Exposure pattern:

```sql
-- MV: no RLS, only service_role can read
-- View: inline WHERE filter enforces tenant isolation
CREATE VIEW public.v_mv_daily_revenue AS
  SELECT * FROM public.mv_daily_revenue
  WHERE salon_id = (
    SELECT u.salon_id FROM public.users u WHERE u.id = auth.uid() LIMIT 1
  );
GRANT SELECT ON public.v_mv_daily_revenue TO authenticated;
REVOKE SELECT ON public.mv_daily_revenue FROM authenticated;
```

Same pattern for `v_mv_audit_stats`. Never expose the raw MV to authenticated.

---

## 11. Global tables (no tenant key)

`feature_flags`, `maintenance_windows`, and `app_versions` are global (no
`salon_id`). They are:
- **Readable** by all authenticated users (needed for feature evaluation)
- **Writable** only via service_role (no authenticated INSERT/UPDATE/DELETE policy)

```sql
CREATE POLICY "feature_flags_authenticated_select"
  ON public.feature_flags FOR SELECT TO authenticated USING (true);
-- No INSERT/UPDATE/DELETE policy → only service_role can write
```

This means an Owner cannot create or modify feature flags — they can only set
per-salon overrides in `salon_feature_overrides`.

---

## 12. Non-negotiable rules

These rules are encoded in AGENT.md and enforced in every phase:

- JAMAIS `DELETE SQL` → toujours soft delete (`deleted_at = now()`)
- JAMAIS `service_role` key dans le code Flutter
- JAMAIS `auth.jwt()` dans les policies RLS → toujours `has_role()`
- JAMAIS hardcoder `LEAPA_API_KEY`, `FCM_SERVICE_ACCOUNT_JSON`, `WHATSAPP_TOKEN` dans le code
- TOUJOURS `RLS ENABLE` sur chaque nouvelle table
- TOUJOURS `has_role()` comme seul mécanisme RLS
- TOUJOURS `salon_id` extrait du JWT (via `public.users`) côté serveur

---

## Update — 2026-07-03 (Enterprise Architecture Expansion, Part 12)

**Correction to §4 "Permission resolution chain"**: that section (as originally written)
describes a `users.permission_group_id` column and a `permission_groups.permissions`/
`role_defaults` JSONB shape. The **real, deployed** `check_permission()` function
(`supabase/migrations/20260629100000_rbac_enterprise.sql`) uses a different, junction-table-based
schema: `permission_definitions` (global catalog) ← `permission_group_permissions` →
`permission_groups` ← `user_permission_groups` → `users`, plus a separate
`user_permission_overrides` table — not a JSONB blob on `users`. Real resolution order: **owner
role → always `TRUE`** (no table lookup needed) → `user_permission_overrides` (highest priority
override) → `bool_or` across every `permission_groups` row the user belongs to via
`user_permission_groups` → default `FALSE`. Cached in `user_effective_permissions_cache`
(server-side, 15-min TTL) and mirrored client-side in the `permission_cache` Hive box (same TTL).
Full schema detail: `docs/DATABASE_ARCHITECTURE.md` §3.1. This correction is appended rather than
rewriting §4 in place, per this pass's additive-only rule — §4 above should be read as
superseded by this note.

Also see `docs/security/SECURITY_ENTERPRISE.md` for the OWASP Mobile Top 10 mapping and
forward-looking hardening items (certificate pinning, Hive encryption, biometric auth, root/
jailbreak detection — all honestly marked ⏳ Planned, none currently implemented).