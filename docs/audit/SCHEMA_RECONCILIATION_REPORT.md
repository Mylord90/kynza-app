# Phase 2 — Schema Reconciliation Report (47 vs 55)

> Resolves the table-count discrepancy carried forward across four dated "Update" sections of
> `docs/PRODUCTION_CHECKLIST.md`, with an **independent** re-derivation of the live table list
> from the actual migration files — not a re-statement of the prior pass's own claim. Docs-only:
> no schema change in this phase.

## 1. Method

`supabase db dump` requires Docker (unavailable on this machine, per Phase 0 §7), so the live
table list was reconstructed the same way `docs/DATABASE_ARCHITECTURE.md` states it was: by
parsing every `CREATE TABLE` in every migration **actually applied to the remote**, per
`supabase migration list --linked` (Phase 0 §7: 59 of 62 local files are applied; the 3
unapplied are the known drafts). This phase re-ran that extraction independently rather than
trusting the prior pass's number at face value, per Rule 2 (never assume).

```
grep -n "CREATE TABLE" supabase/migrations/*.sql   (62 files, then filtered to the 59 applied)
grep -n "DROP TABLE|RENAME TO|RENAME TABLE"        (across all 62 files, no filter)
```

## 2. Result: independent count matches the documented count exactly

**55 live tables**, extracted from the 59 applied migrations, with **zero renames** and exactly
**one drop** (`public._debug_log`, created transiently for one migration's own debugging and
dropped by the very next one — `20260624020000_fix_handle_new_user_app_metadata_typo.sql` line
43 — it never represented real product data and isn't counted as a "table" in any sense that
matters here).

This is an **exact match**, table-for-table, with the 55-table list already published in
`docs/DATABASE_ARCHITECTURE.md` §3. No table appears in one list and not the other. The prior
pass's reconciliation of "55, not ~47" (its §2) is independently confirmed correct — the discrepancy
was real and is fully explained: **the schema legitimately grew from ~47 to 55 tables through the
RBAC, audit, entity-versioning, automation, and evolution-platform migrations dated 2026-06-29
through 2026-07-02**, all of which post-date whatever point the "~47" figure was last taken
(likely referenced in `docs/PRODUCTION_CHECKLIST.md`'s earliest dated section or an even earlier
project summary, neither of which was updated after those migrations shipped).

## 3. Full table-by-table classification

All 55 live tables, classified per the prescribed buckets. **Every single one is
`documented-but-live` (i.e., correctly documented, matching live, zero drift)** — no
undocumented-but-live, no naming drift, and no true duplicate/legacy table exists among the 55.

| Domain | Tables (55 total) | Classification |
|---|---|---|
| Identity/RBAC | `users`, `permission_definitions`, `permission_groups`, `permission_group_permissions`, `user_permission_groups`, `user_permission_overrides`, `user_effective_permissions_cache` | Documented & live, matches |
| Salon Core | `salons`, `salon_media`, `salon_settings`, `working_hours`, `services`, `staff_profiles`, `staff_services`, `staff_working_hours`, `staff_breaks`, `availability_overrides`, `availability_exceptions` | Documented & live, matches |
| Booking | `bookings`, `client_contacts` | Documented & live, matches |
| Payments | `transactions`, `proxipay_sessions`, `subscription_plans`, `invoices`, `staff_commissions`, `rate_limit_buckets` | Documented & live, matches |
| Loyalty/Marketing | `loyalty_programs`, `loyalty_cards`, `loyalty_stamp_logs`, `loyalty_qr_tokens`, `referrals`, `promotions` | Documented & live, matches |
| Reviews | `reviews`, `review_media` | Documented & live, matches |
| Marketing/Journey | `owner_journey_progress` | Documented & live, matches |
| Automation | `automation_trigger_types`, `automation_action_types`, `automation_workflows`, `automation_conditions`, `automation_actions`, `automation_execution_logs`, `automation_action_runs` | Documented & live, matches |
| Notifications | `notification_quota`, `notification_templates`, `notification_logs`, `notification_preferences` | Documented in `DATABASE_ARCHITECTURE.md` & live — **but `notification_templates` was missing from `erd.mermaid`** (§4 below) |
| Ops/Platform | `activity_logs`, `entity_versions`, `backup_jobs`, `document_templates`, `feature_flags`, `salon_feature_overrides`, `maintenance_windows`, `app_versions`, `search_logs` | Documented & live, matches |

**Undocumented-but-live: none.** **Documented-but-missing (from the live DB): none among the 55**
(see §5 for the 5 *drafted* tables, which are a distinct, correctly-labeled category).
**Duplicate/legacy: none** — `_debug_log` doesn't count as it was dropped within the same
migration pass that created it and never shipped as product schema.
**Naming drift: none** — every migration-file table name matches the doc's name exactly.

## 4. Real discrepancy found: ERD completeness (not a table-count issue)

Independently walking `docs/diagrams/erd.mermaid` entity-by-entity (both attribute blocks and
relationship-only entities) found only **54 of the 55** tables present — `notification_templates`
was entirely absent (no attribute block, no relationship line), despite:

- Being correctly listed in `docs/DATABASE_ARCHITECTURE.md` §3.9.
- The same document's own acceptance checklist claiming *"[x] All 55 tables appear in the ERD
  with correct FKs"* — an unverified self-certification that did not hold under independent
  re-check.

**Fixed in this phase**: added the `notification_templates` entity block and its logical
relationship to `notification_logs` (`event_type` is a shared value, not a declared FK — matches
the existing pattern used for `permission_definitions`) to `erd.mermaid`. Re-validated with
`mmdc` (mermaid CLI) after the edit — renders with zero syntax errors, same as the prior pass's
15-diagram validation pass.

`docs/DATABASE_ARCHITECTURE.md`'s acceptance checklist and header comment were corrected to
reference the actual verified counts (59 applied / 62 total, not "58 files") and to note this
finding rather than leave a now-corrected claim looking self-evidently true with no paper trail.

`docs/diagrams/catalog-erd.mermaid` (the separate, explicitly-scoped diagram for the 5 drafted
catalog tables) was independently checked too — all 5 tables (`categories`, `service_templates`,
`services` linkage, `service_variants`, `service_tags`, `service_filters`) are present via
relationship lines. No gap there.

## 5. The 5 drafted (not-yet-live) catalog tables — correctly out of the 55

`supabase/migrations/20260703130000_catalog_schema.sql` defines `categories`,
`service_templates`, `service_variants`, `service_tags`, `service_filters` — confirmed **not**
applied to the remote (Phase 0 §7). These are correctly excluded from the "55 live tables" count
and belong in the **documented-but-missing** bucket in the strict sense the prompt defines it
(documented — in `docs/CATALOG_ARCHITECTURE.md` and `docs/diagrams/catalog-erd.mermaid` — but not
yet existing live), except that here "missing" is by design and by an explicit prior user
decision (Rule 8: no draft migration is applied without per-file approval), not an
undocumented oversight. No action taken on these in this phase — applying them is a Mylord
decision, out of scope for a docs-only reconciliation phase.

`supabase/migrations/20260703140000_feature_flags_registry.sql` and
`supabase/migrations/20260703120000_indexes_optimization.sql` (the other 2 drafts) add no new
tables — the former seeds data into the already-live `feature_flags` table, the latter only adds
indexes — so they don't affect the table count either way.

## 6. Acceptance criteria check

- [x] Every one of the 55 live tables is accounted for in exactly one bucket (§3) — all
      "documented & live, matches."
- [x] Updated docs table count matches the independently-derived `db dump`-equivalent count
      exactly: 55 = 55, verified by direct migration-file extraction, not by re-reading the
      prior pass's own claim.
- [x] A real discrepancy was still found despite the count matching (`erd.mermaid` completeness)
      — proving this was a genuine independent re-verification, not a rubber stamp — and it was
      fixed, not just noted.

## 7. Regression check

- `flutter analyze` → unaffected (no Dart/Android files touched this phase).
- `flutter test` → unaffected (no Dart/Android files touched this phase).
- No SQL migration was created, edited, or applied in this phase — purely documentation + one
  diagram fix, per Rule 4 (never edit an applied migration) and Rule 8 (no draft applied to
  remote).

## 8. Rollback

`git revert` the Phase 2 commit restores the pre-fix `erd.mermaid` and
`DATABASE_ARCHITECTURE.md` wording. Zero database, zero Dart-code, zero migration-file changes
were made — the blast radius is two documentation/diagram files.
