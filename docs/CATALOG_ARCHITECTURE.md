# KYNZA — Service Catalog Architecture

> Part 5 of the Enterprise Architecture & Documentation Expansion. All schema referenced here is
> **drafted, not applied** to the remote project — see §11. Grounded against the real
> `services` table (`docs/DATABASE_ARCHITECTURE.md` §3.2) and the app's current free-text
> category list (`lib/core/constants/service_categories.dart`, 14 values).

## 1. Objectifs

Today, `services.category` is a free-text `TEXT NOT NULL` column with no lookup table — every
owner types (or picks from a hardcoded 14-item Dart list) a category name with no normalization,
no hierarchy, no icon/image, and no way to filter client discovery by category tree. This part
introduces a data-driven, code-free-to-extend taxonomy an admin can grow via Supabase Studio
alone, without a Flutter redeploy — while leaving every existing `services` row and code path
untouched.

## 2. Architecture

### 2.1 Why not literally reuse the brief's `services(...)` schema

The brief's proposed schema — `services (id, category_id, salon_id, name, description,
base_duration_minutes, base_price_fbu, deleted_at)` — is column-for-column the **existing**,
already-live, salon-scoped `services` table. Seeding "2 services per sub-category" as literal
rows in that table would require attaching each one to a real `salon_id`, which doesn't exist
for a global catalog — it would pollute a real owner's service list with fake entries.

**Resolution** (documented deviation, not a silent reinterpretation): introduce
`service_templates` — a new **global**, admin-curated catalog table — to hold the seed/reference
content ("suggested services per sub-category"). The existing `services` table gains two
nullable, additive columns (`category_id`, `source_template_id`) so a real service can optionally
link into the taxonomy. `services.category` (free text) is untouched — that's exactly how the
required "Autre" custom/free-text catch-all keeps working with zero special-casing.

### 2.2 Data model

```
categories            (id, parent_id → categories, slug, name_fr, name_en, icon, image_url,
                        gender_scope, sort_order, is_active, deleted_at)
service_templates      (id, category_id → categories, name, description, gender_scope,
                        default_duration_minutes, default_price_bif, default_variants JSONB,
                        is_active, deleted_at)
services               (EXISTING table, +2 nullable columns: category_id → categories,
                        source_template_id → service_templates)
service_variants        (id, service_id → services, name, duration_delta_minutes,
                        price_delta_bif, sort_order, is_active, deleted_at)
service_tags           (id, service_id → services, tag, deleted_at)
service_filters        (id, service_id → services, filter_key, filter_value, deleted_at)
```

`categories.parent_id` self-references for unlimited depth (category → sub-category → ... —
the seed only populates 2 levels, but the schema supports more). `gender_scope` is
`TEXT CHECK IN ('femme','homme','mixte','enfant')` — matching this schema's house style
(`TEXT` + `CHECK`, no native Postgres `ENUM` type is used anywhere else in this codebase, so this
follows suit rather than introducing a new pattern).

`service_templates.default_variants` is a JSONB array (e.g. `[{"name":"Cheveux longs",
"duration_delta_minutes":30,"price_delta_bif":6000}]`) rather than a child table — it's seed/
reference data with no FK integrity requirement of its own. **Real** per-service variants
(`service_variants`) remain a proper child table with a real FK to a real `services` row, since
those participate in actual pricing/booking calculations.

### 2.3 Instantiation flow (design, no new Flutter screens built in this pass)

```
Owner opens "Add service" → picker shows categories tree (public SELECT, RLS)
  → picks a service_template (or "Autre" → free text, unchanged today's flow)
  → app creates a real services row:
      services.category_id = template.category_id
      services.source_template_id = template.id
      services.name/duration_min/price_bif = pre-filled from the template
        (owner can edit before saving — template values are defaults, not locked)
      services.category (legacy free-text) = category.name_fr, kept in sync for
        any code path still reading the old column
  → owner may optionally add real service_variants under the new services row,
    seeded from template.default_variants as a starting point
```

This flow is a **design**, not a shipped Flutter feature — Part 5's scope is the data model,
seed, and extension guide, not new UI screens (see §11 for exact deliverables).

## 3. Workflow / Data Flow

See §2.3. Client-facing discovery (`SalonDiscoveryScreen`, `AdvancedSearchScreen`) can filter by
`categories.slug`/`gender_scope` once a future iteration wires `services.category_id` into the
search RPC (`search_salon_data`) — not built in this pass, but the schema supports it without
another migration (the new `idx_services_category_id` index is already in place for that).

## 4. Structure & Conventions

- Slugs: `kebab-case`, ASCII (accents stripped — e.g. `defrisage` for "Défrisage"), stable once
  published (never renamed — see `CATALOG_EXTENSION_GUIDE.md`'s "never rename a slug" rule).
- Icon naming: `ic_<slug_with_underscores>` (e.g. `ic_coiffure_femme`), matching the asset
  convention defined in Part 8 (`docs/ASSETS_GUIDE.md`) — the seed script already emits this
  format so no follow-up rename pass is needed once icon assets exist.
- Sub-category naming: `"<Parent> — Classique"` / `"<Parent> — Premium"` (2 tiers per top-level
  category, per the seed's systematic generation — see §5).

## 5. Contraintes & Edge Cases

- **Pricing is extrapolated, not observed.** No live production-data read was performed for this
  pass (deliberately — reading real customer/salon financial data for a documentation task was
  judged out of scope without explicit sign-off). The one real, verified anchor point is
  `test/unit/booking_flow_notifier_test.dart`'s fixture: a 30-minute "Coiffure Homme" service at
  10 000 BIF. All other band prices are extrapolated from that single point by service-type
  category, not pulled from real salons' actual `services.price_bif` values. **Owners must review
  and adjust seeded template prices before relying on them** — this is explicitly flagged in
  `CATALOG_EXTENSION_GUIDE.md`.
- The 72 top-level categories × 2 tiers × 2 fragments = 288 `service_templates` rows are
  generated from an 11-band config (HAIR_WOMEN, HAIR_MEN, HAIR_KIDS, WELLNESS_SPA, FACE_SKIN,
  MAKEUP, NAILS, HAIR_REMOVAL, BODY_ART, LIFESTYLE, PREMIUM_NICHE), not hand-authored per node —
  by design, per the brief's own "config-driven, not 70 hand-typed blocks" instruction. Expect
  some genericness in naming (e.g. every PREMIUM_NICHE category gets the same two fragment
  names, "Formule Essentielle"/"Formule Signature") — this is a deliberate maintainability
  trade-off, documented so it isn't mistaken for an oversight.
- `services.category` (free text) and `services.category_id` (new FK) can diverge if an owner
  edits the free-text field directly after linking a template — no trigger enforces sync. This is
  intentional (never force-overwrite an owner's own edit) but means any future reporting by
  `category_id` should not assume `category` always matches.

## 6. Sécurité

- `categories`/`service_templates`: RLS enabled, public `SELECT` (active + not deleted) only — no
  `INSERT`/`UPDATE`/`DELETE` policy for `authenticated`. Writes are Supabase-Studio/service-role
  only, per `CATALOG_EXTENSION_GUIDE.md`. This mirrors the existing
  `automation_trigger_types`/`notification_templates` pattern (`docs/DATABASE_ARCHITECTURE.md`
  §3.8/3.9) rather than inventing a new access pattern.
- `service_variants`/`service_tags`/`service_filters`: owner/manager manage via an `EXISTS` join
  to the parent `services` row's `salon_id` (same pattern as `automation_conditions`/
  `automation_actions`, `docs/DATABASE_ARCHITECTURE.md` §3.8) — `salon_id` is never duplicated
  onto these child tables, it's always resolved transitively through `service_id`.
- All 5 new tables (`categories`, `service_templates`, `service_variants`, `service_tags`,
  `service_filters`) have RLS enabled and a `deleted_at` column, per the hard constraint that
  every new table requires both — even where an equivalent *existing* table in this schema
  lacks one (e.g. `automation_conditions` has no `deleted_at`; these new tables do, because the
  rule governing new tables is stricter than the legacy pattern).

## 7. Performance

- `idx_categories_parent`, `idx_categories_active`, `idx_service_templates_category`,
  `idx_services_category_id` cover the expected read patterns (tree traversal, active-only
  listing, template-by-category, service-by-category).
- `idx_service_tags_tag_trgm` (GIN trigram) mirrors the existing `idx_salons_name_trgm`/
  `idx_services_name_trgm` pattern for fuzzy tag search.
- 288 seeded `service_templates` rows is a small, fully-cacheable dataset client-side (well under
  any pagination threshold) — no special performance handling needed at this scale.

## 8. Stratégie de tests

Not covered by the 244 existing Flutter tests (no Dart code changed in this pass — schema/seed
only). Recommended before applying: a `pgTAP` or manual-review pass confirming (a) the seed
script is idempotent (run twice, row counts don't grow the second time — spot-checked by hand
during authoring, not executed against the remote per the no-live-DB-access decision in §5), and
(b) the new RLS policies don't accidentally expose one salon's `service_variants`/`service_tags`
to another (verified by construction — the `EXISTS` join always scopes through `services.salon_id`
via `has_role()`, same as every other owner/manager-scoped policy in this schema).

## 9. Documentation associée

- `docs/CATALOG_EXTENSION_GUIDE.md` — how a non-developer adds a category via Supabase Studio.
- `docs/DATABASE_ARCHITECTURE.md` §3.2 — the existing `services` table this extends.
- `docs/ASSETS_GUIDE.md` (Part 8) — `cat_<slug>.png`/`ic_<slug>` icon/image naming convention.
- `docs/PRODUCTION_CHECKLIST.md` — this migration's "drafted, not applied" status tracked there.

## 10. Critères d'acceptation

- [x] `CATALOG_EXTENSION_GUIDE.md` proves a non-developer can add a category via SQL/Supabase
      Studio alone (see that document).
- [x] Seed script is idempotent by construction: every category INSERT keys off `ON CONFLICT
      (slug) DO NOTHING` with a re-`SELECT` fallback to resolve the id either way; every
      `service_templates` INSERT keys off a real `UNIQUE (category_id, name)` constraint added in
      the same migration (not a no-op bare `ON CONFLICT DO NOTHING`, which was caught and fixed
      during authoring — see the migration file's inline comment).
- [x] ≥70 top-level categories present post-seed — 72 confirmed by direct count of the config
      table's rows.
- [x] Nothing in `services` (existing table) was altered beyond two additive nullable columns —
      zero existing rows, RLS policies, indexes, or triggers touched.

## 11. Livrables

- `supabase/migrations/20260703130000_catalog_schema.sql` — **drafted, NOT applied** to the
  remote (per your decision on Part 5's migration risk — this repo has no local Supabase/Docker
  stack, `db push` hits the live project directly).
- `supabase/seed/categories_seed.sql` — **drafted, NOT applied**; depends on the schema migration
  above being applied first.
- `docs/CATALOG_ARCHITECTURE.md` (this file)
- `docs/CATALOG_EXTENSION_GUIDE.md`
