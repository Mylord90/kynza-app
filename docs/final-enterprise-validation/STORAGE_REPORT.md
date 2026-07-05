# CP2 — Supabase Storage `[NEW DEPTH]`

> First time Storage has been examined this deeply. All findings below are real query/SQL results
> against production (`hhdkjfpgaklhrhfoxlhj`, read-only) and `kynza-dr-scratch`
> (`hzjmyeptytvjmzbnsmwp`, used for the actual RLS write-attempt exploit tests so no write ever
> touches production, per Rule 8).

## 1. Buckets (production, real config)

| bucket | public | file_size_limit | allowed_mime_types | objects (real count) |
|---|---|---|---|---|
| `kynza-media` | true | **none set** | **none set** | 0 |
| `kynza-backups` | false | **none set** | **none set** | 0 |

**Real finding, not previously flagged**: neither bucket has a `file_size_limit` or
`allowed_mime_types` configured at the bucket level. Nothing today stops an authorized uploader
from pushing an arbitrarily large file or an arbitrary MIME type (e.g. an executable disguised
with an image extension) into `kynza-media`. Low urgency only because real usage is currently
zero (§3) — becomes relevant the moment `StorageService` (see §4) is exercised by real users.

Both projects (prod and dr-scratch) have identical bucket configuration, confirming the storage
migration is consistent across environments.

## 2. RLS policies on `storage.objects` (production, real `pg_policies` read)

| policy | cmd | rule |
|---|---|---|
| `kynza_backups_owner_read` | SELECT | `bucket_id='kynza-backups' AND has_role(auth.uid(),'owner', folder[2]::uuid)` |
| `kynza_media_public_read` | SELECT | `bucket_id='kynza-media'` — **no restriction**, by design (public marketplace photos) |
| `kynza_media_owner_manager_write/update/delete` | INSERT/UPDATE/DELETE | scoped to `has_role(owner\|manager, folder[2]::uuid)` |
| `kynza_media_self_avatar_write/update` | INSERT/UPDATE | scoped to `folder[1]='user' AND folder[2]=auth.uid()` |

No INSERT/UPDATE/DELETE policy exists for `kynza-backups` under `authenticated`/`anon` — writes are
service_role-only (the `create-backup` Edge Function), matching AGENT.md §5's design.

## 3. Live exploit tests against `kynza-dr-scratch` (real, not code-reviewed)

Tests impersonate a real seeded `staff` user (`SET LOCAL role authenticated` +
`request.jwt.claims` set to their real `sub`) attempting the direct `storage.objects` INSERT/SELECT
a client normally reaches only through the Storage API — this is the same technique Remediation
v1 used for its live P0/P1/P2 exploit tests, applied here to Storage for the first time.

| # | Attempt | Expected | Real result |
|---|---|---|---|
| A | Staff writes into **another salon's** `kynza-media` folder | blocked | **BLOCKED** (`insufficient_privilege`) |
| B | Staff writes into their **own** salon's `kynza-media` folder (staff isn't owner/manager) | blocked | **BLOCKED** (`insufficient_privilege`) |
| C | Staff writes their **own** avatar path | allowed | **SUCCEEDED** (correct) |
| D | Staff writes **another user's** avatar path | blocked | **BLOCKED** (`insufficient_privilege`) |
| E | **Unauthenticated** (`anon`) reads `kynza-backups` | 0 rows visible | **0 rows** (confirmed) |

All 5 outcomes match the intended policy. This is a genuine test of the bucket-level RLS, not a
restatement of the `pg_policies` definitions in §2 — the policies were executed against real rows
under an impersonated session, and every cross-tenant/cross-user attempt failed exactly as
designed. **Storage security posture: passes on the vectors tested.**

Note on the anon-read-`kynza-media` case: it was **not** tested as a negative case, because there
is nothing to leak — `kynza_media_public_read` is intentionally unrestricted (it's the salon
photo/service-image directory, meant to be public), and 0 objects exist to leak regardless (§4).

## 4. Real usage: storage is functionally unused in both environments

`storage.objects` row counts: `kynza-media` = **0** on both production and dr-scratch;
`kynza-backups` = **0** on production, **1** on dr-scratch (the real backup object created by
Remediation v1's Phase 0 restorability test).

This is not a gap in this checkpoint's testing — `StorageService`
(`lib/core/services/storage_service.dart`) **is** wired into real screens
(`salon_repository_impl.dart`, `client_profile_providers.dart`, covering salon
logo/cover/portfolio upload and user avatar upload), but no real user has exercised any of those
upload flows in production yet, consistent with CP1's finding that production overall holds
almost no real data yet.

**New finding, code-level**: `StorageService._upload`/`uploadUserAvatar` call
`uploadBinary(path, bytes)` with no `FileOptions` — no explicit `cacheControl` (defaults to the
Supabase SDK's 3600s), and **no server-side WebP compression**, despite AGENT.md §5 stating
"Médias : Supabase Storage + CDN (compression WebP obligatoire côté serveur)". Whatever byte
format the Flutter client sends (presumably already compressed client-side, not verified in this
checkpoint — that would require tracing the picker/cropper call sites, out of this checkpoint's
storage-layer scope) is stored as-is; there is no Edge Function or Postgres trigger performing
server-side WebP transcoding. Tracked in `FINAL_ROADMAP.md`.

## 5. Orphan file detection (real query, not an estimate)

```sql
SELECT o.name FROM storage.objects o
WHERE o.bucket_id = 'kynza-media'
  AND NOT EXISTS (SELECT 1 FROM salon_media sm WHERE sm.url LIKE '%'||o.name||'%' OR sm.thumbnail_url LIKE '%'||o.name||'%')
  AND NOT EXISTS (SELECT 1 FROM review_media rm WHERE rm.url LIKE '%'||o.name||'%')
  AND (storage.foldername(o.name))[1] != 'user';
```
Result: **0 rows**, on both projects — because `kynza-media` holds 0 objects total, not because
orphan-detection logic found none among many. The single real object in `kynza-backups`
(dr-scratch) **is** correctly referenced by `backup_jobs.storage_path` (job `3d8631a1...`, status
`completed`, `file_size_bytes=2888` matching the object's real metadata size exactly) — genuine
zero-orphan confirmation on the one real file that exists. The query itself is validated as
correct (it successfully matched the real backup row); it has nothing to find yet at real volume.

## 6. Quota headroom

Real usage is 0 bytes in both buckets on both projects, so headroom is not a near-term concern by
construction. The exact plan-tier byte quota was **not retrievable** — the installed Supabase CLI
(v2.107.0) exposes no `usage`/`quota` subcommand, and pulling it would require an authenticated
call to the Management API's billing/usage endpoint, which this environment doesn't have set up.
Stated honestly rather than guessed: **quota ceiling: not testable in this environment; real usage
against it: 0 bytes, confirmed.**

## 7. What this checkpoint did not test

- No lifecycle/expiration policy exists to test — Supabase Storage has no native TTL/lifecycle
  rule mechanism, and no custom cron-based cleanup Edge Function was found in
  `supabase/functions/`. Not a gap in testing; there is genuinely nothing here to exercise yet.
- Did not trace whether the Flutter-side image picker already compresses/resizes before calling
  `StorageService` (would need to inspect picker/cropper widgets — UI-layer, not storage-layer,
  out of this checkpoint's scope).
- Did not load-test upload throughput/concurrency — there's no real upload traffic pattern to
  reproduce yet; revisit once CP6 or real usage establishes one.
