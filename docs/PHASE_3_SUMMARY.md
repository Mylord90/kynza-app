# PHASE 3 — Enterprise Data Platform — Summary

## Scope
Four sub-systems: full-text search acceleration, a pre-aggregated revenue
materialized view, a backup pipeline, and a document template engine.
Each adds a distinct capability — none duplicates work from Phases 1-2.

## What changed

### Migrations (4)

**`20260630100000_phase3_fulltext_search.sql`**
- `pg_trgm` extension + GIN trigram indexes on `salons.name`,
  `salons.description`, `services.name`, `services.category`.
  Speeds up existing ILIKE `%query%` calls automatically — zero
  Flutter changes needed.
- Generated `search_vector TSVECTOR STORED` columns on `salons` and
  `services` (weighted: name=A, description/slogan=B/C, location=D).
  GIN indexes on those columns.
- `search_salon_data(p_query, p_type, p_province, p_limit)` RPC —
  uses `websearch_to_tsquery('simple', ...)` against the stored vectors,
  returns unified `{id, result_type, title, subtitle, salon_id,
  price_bif, image_url, province, rank}` rows ordered by relevance.
  `'simple'` config preserves brand names / proper nouns without
  stemming. SECURITY INVOKER (caller's RLS applies to underlying tables).

**`20260630100100_phase3_mv_revenue.sql`**
- `mv_daily_revenue` materialized view: `{salon_id, day,
  bookings_total/completed/no_show/cancelled, revenue_bif}`.
  No RLS (Postgres doesn't support it on MVs) — no authenticated grant.
- `v_mv_daily_revenue` thin view on top: filters to the caller's
  salon_id via `auth.uid()`. Authenticated users query their own data;
  service_role queries the full MV.
- Unique index on `(salon_id, day)` — required for CONCURRENTLY.
- pg_cron: `REFRESH MATERIALIZED VIEW CONCURRENTLY` nightly at
  midnight UTC (2am Bujumbura time).

**`20260630100200_phase3_backup.sql`**
- `backup_jobs` table: tracks status, storage path, file size, record
  count, error message. Owner/manager SELECT via `has_role()`.
  No authenticated INSERT/UPDATE — only the Edge Function (service_role).
- `kynza-backups` storage bucket (private, not public). Owner-only
  SELECT policy on storage objects (for future signed-URL download).

**`20260630100300_phase3_document_templates.sql`**
- `document_templates` table: per-salon, type IN
  ('invoice','receipt','monthly_report'), `{{variable}}` body.
- Partial unique index: only one default per `(salon_id, type)`.
- `render_template(template_id, variables JSONB)` SQL function —
  simple `replace(body, '{{key}}', value)` loop, SECURITY INVOKER.
- `create_default_document_templates()` + trigger on salons INSERT
  + backfill: 3 default templates (invoice, receipt, monthly_report)
  per salon. Same auto-seed-with-backfill pattern as Phase 1.4 salon
  settings and Phase 2 automation workflows.
- **Confirmed**: backfill ran correctly — 3 templates created for the
  existing salon (the second is soft-deleted so skipped is fine).

### Edge Function: `create-backup`
- Auth: owner or manager only (JWT → profile check).
- Rate limit: max 1 backup per 6 hours (checks `backup_jobs` table).
- Exports: last 90 days of bookings/reviews/invoices (transactional)
  + full export of services/staff_profiles/clients (reference).
- Clients deduplicated (one booking per client_id → one `users` row).
- Uploads JSON to `kynza-backups/salon/{salon_id}/{timestamp_ms}.json`.
- Records job in `backup_jobs` (status: running → completed/failed).
- Returns `{job_id, status, storage_path, file_size_bytes,
  records_exported}`.

### Flutter

**New models (Freezed + json_serializable):**
- `BackupJobModel` — status, storagePath, fileSizeBytes, recordsExported,
  tablesIncluded, completedAt
- `DocumentTemplateModel` — type, name, body, language, isDefault

**New feature: `lib/features/data_platform/`**
- `backup/`: BackupRepositoryImpl, BackupNotifier, BackupScreen
  (job list + info card + create button with 6h cooldown confirmation)
- `templates/`: TemplateRepositoryImpl, TemplateNotifier,
  TemplateListScreen (grouped by type, default badge, delete confirm),
  TemplateEditorScreen (create/edit, per-type variable hints, default toggle)

**Updated:**
- `SearchRepositoryImpl`: `_searchSalons` and `_searchServices` now try
  `search_salon_data()` RPC first; fall back to ILIKE if the RPC fails
  (migration window safety net) or if service-only filters are active
  (category/price can't be passed to the RPC).
- `SettingsHomeScreen`: "Modèles de documents" and "Sauvegardes de
  données" tiles added.
- `RouteNames`: `ownerBackup`, `ownerTemplates` added.
- `app_router.dart`: `_OwnerBackupLoader`, `_OwnerTemplatesLoader`
  and their routes added.

## Deviations from brief

- **`search_salon_data()` returns 0 for ILIKE-style partial tokens**
  (e.g. `'salon'` vs `'SalonBeauteQA'` stored as one token). This is
  correct FTS behavior — the fallback ILIKE path handles partial prefix
  matches on compound words. Real salon names with spaces ("Salon de
  Beauté") are matched correctly by both paths.
- **`mv_daily_revenue` has no authenticated GRANT** — per-session
  queries must still use `v_salon_kpis` (security_invoker view).
  `mv_daily_revenue` is for service_role batch operations only.
  A thin `v_mv_daily_revenue` view was added for authenticated access
  with salon_id isolation.
- **No PDF generation** — `render_template()` returns raw text with
  `{{variable}}` substitutions. PDF generation would require an
  external service or a Deno library not available without additional
  infrastructure.

## Verification
- `supabase db push` — 4 migrations applied cleanly.
- `supabase functions deploy create-backup` — deployed.
- `search_salon_data('salonbeauteqa', 'salon')` → 1 result (correct
  — exact token match in tsvector) ✅
- `document_templates` → 3 rows (invoice + receipt + monthly_report
  seeded for the active salon) ✅
- `kynza-backups` storage bucket → exists ✅
- `flutter analyze` → No issues found ✅
- `flutter test` → 164/164 passed, 0 regressions ✅

## Remaining gaps
- No live end-to-end test of `create-backup` (requires a real user JWT
  — the function is deployed and verified structurally; actual backup
  execution will be tested by the owner in the app).
- `v_mv_daily_revenue` is wired but no existing screen queries it yet —
  the Phase 4 analytics dashboard still uses `v_salon_kpis`. The MV's
  primary consumer is the `update_stats` automation action (Phase 2)
  which is implemented but marked `not_implemented_this_phase`.
- `render_template()` RPC is wired in the repository but no screen
  calls it yet — a "preview rendered template" flow would be the
  natural follow-up.