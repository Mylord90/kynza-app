# KYNZA — Catalog Extension Guide

> Proves the Part 5 taxonomy is addable by a non-developer via Supabase Studio alone, with no
> Flutter redeploy. Assumes `supabase/migrations/20260703130000_catalog_schema.sql` has already
> been reviewed and applied (see `docs/CATALOG_ARCHITECTURE.md` §11 — it is drafted, not applied,
> as of this writing).

## Adding a new top-level category (no code, no redeploy)

1. Open **Supabase Studio → Table Editor → `categories`**.
2. Click **Insert row**. Fill in:
   - `slug` — lowercase, hyphenated, ASCII only (e.g. `soins-corps`). **Never reuse or rename an
     existing slug once published** — the app may cache it client-side (search filters, deep
     links) and a rename silently orphans anything referencing the old value. If a category needs
     renaming, change `name_fr`/`name_en` only; the slug is a stable identifier, not a display
     string.
   - `parent_id` — leave `NULL` for a top-level category, or paste another category's `id` to
     nest it (any depth — the schema doesn't cap it, though the seed only ever generates 2
     levels).
   - `name_fr` (required), `name_en` (optional — falls back to `name_fr` client-side if blank;
     no code enforces this fallback today, it's a UI convention to apply when the picker is
     built).
   - `gender_scope` — one of `femme`, `homme`, `mixte`, `enfant` (the column has a `CHECK`
     constraint — any other value is rejected at the database level, not just in the UI).
   - `icon` — a string like `ic_soins_corps` (see `docs/ASSETS_GUIDE.md` for the asset this
     should eventually map to — the row can be created before the icon asset exists; the UI would
     fall back to a default icon).
   - `sort_order` — an integer; lower sorts first. Leave gaps (e.g. multiples of 10) so you can
     insert between existing categories later without renumbering everything.
   - `is_active` — defaults to `true`. Set `false` to hide a category from clients without
     deleting it (soft toggle, distinct from `deleted_at`).
3. Save. **That's it** — no app update, no cache to bust server-side. The category appears in any
   screen reading `categories` on its next fetch (RLS already allows public `SELECT` on active,
   non-deleted rows).

## Adding a service template under a category

1. Find the target category's `id` (Table Editor → `categories`, or `SELECT id FROM categories
   WHERE slug = '...'`).
2. Open **`service_templates` → Insert row**:
   - `category_id` — the category's `id` from step 1.
   - `name`, `description`.
   - `default_duration_minutes`, `default_price_bif` — **plain integers, no formatting** (the app
     formats BIF display client-side via `CurrencyFormatter`; never insert a pre-formatted string
     like `"15 000 FBu"` here).
   - `default_variants` — a JSON array, e.g.
     `[{"name":"Cheveux longs","duration_delta_minutes":30,"price_delta_bif":6000}]`. Leave `[]`
     if the service has no variants.
3. Save. This becomes a suggestion in the (future) owner-facing "Add service" picker — it never
   auto-creates a real `services` row anywhere; an owner has to explicitly pick it.

## Removing a category or template

**Never** run `DELETE FROM categories` or `DELETE FROM service_templates` — this schema has zero
tolerance for hard deletes on any table, new or old (project-wide rule, see
`docs/SECURITY.md`). Instead: `UPDATE categories SET deleted_at = NOW() WHERE id = '...'`. RLS
immediately hides it from every `SELECT` policy (all of which filter `deleted_at IS NULL`).

## Re-running the seed script safely

`supabase/seed/categories_seed.sql` is idempotent — re-running it after adding your own rows
manually will not duplicate anything:
- Top-level and sub-categories key off `ON CONFLICT (slug) DO NOTHING`.
- Service templates key off a real `UNIQUE (category_id, name)` constraint, also
  `ON CONFLICT ... DO NOTHING`.

To verify this yourself before trusting it in production: run the script once, note
`SELECT count(*) FROM categories` and `SELECT count(*) FROM service_templates`, run it again,
confirm the counts are identical.

## What this guide does NOT cover

Building the actual Flutter "Add service from template" picker screen is out of scope for this
documentation pass (Part 5 delivers the data model + seed + this guide, not new UI) — see
`docs/CATALOG_ARCHITECTURE.md` §2.3 for the intended flow a future implementation should follow.
