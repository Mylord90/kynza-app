-- DRAFT — reviewed but NOT applied to the remote project as part of the
-- Enterprise Architecture & Documentation Expansion pass (Part 5, docs/CATALOG_ARCHITECTURE.md).
-- This repo has no local Supabase/Docker stack; `supabase db push` hits the live
-- project (hhdkjfpgaklhrhfoxlhj) directly. Apply manually after review.
--
-- Adds a global, data-driven service taxonomy on top of the existing per-salon
-- `services` table WITHOUT touching any existing column, row, or RLS policy on
-- that table. `services.category` (free text) is left exactly as-is — existing
-- code paths keep working unchanged. Two new NULLABLE columns let a service
-- optionally link into the new taxonomy; NULL means "custom / free-text only",
-- which is how the required "Autre" catch-all works with zero schema special-casing.
--
-- Design note (documented, not silently assumed): the original brief's proposed
-- `services (id, category_id, salon_id, name, ..., base_price_fbu)` schema is
-- column-for-column the EXISTING `services` table (salon-scoped). Seeding literal
-- rows into that table would attach fake template services to a real salon_id,
-- which doesn't exist for a global catalog. Instead this migration introduces
-- `service_templates` (global, admin-curated) to hold the "2 services per
-- sub-category" seed content; an owner instantiates a real `services` row from a
-- template (or from scratch) via the app, at which point normal salon-scoped
-- `service_variants`/`service_tags`/`service_filters` apply to that real service.

-- 1. categories — global, self-referencing taxonomy tree (unlimited depth via parent_id)
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID REFERENCES public.categories(id) ON DELETE CASCADE,
  slug TEXT NOT NULL UNIQUE,
  name_fr TEXT NOT NULL,
  name_en TEXT,
  icon TEXT,
  image_url TEXT,
  gender_scope TEXT NOT NULL DEFAULT 'mixte'
    CHECK (gender_scope IN ('femme', 'homme', 'mixte', 'enfant')),
  sort_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_categories_parent
  ON public.categories (parent_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_categories_active
  ON public.categories (is_active, sort_order) WHERE deleted_at IS NULL;

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "categories_public_select" ON public.categories
  FOR SELECT USING (deleted_at IS NULL AND is_active = true);
-- No INSERT/UPDATE/DELETE policy for `authenticated` — catalog is admin/service_role
-- managed (via Supabase Studio or a future admin tool), per docs/CATALOG_EXTENSION_GUIDE.md.
-- This mirrors the existing automation_trigger_types / notification_templates pattern.

CREATE TRIGGER categories_updated_at
  BEFORE UPDATE ON public.categories
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 2. service_templates — global catalog of suggested services per category, used
-- to populate an owner-facing picker. Never referenced by a booking directly.
CREATE TABLE IF NOT EXISTS public.service_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  gender_scope TEXT NOT NULL DEFAULT 'mixte'
    CHECK (gender_scope IN ('femme', 'homme', 'mixte', 'enfant')),
  default_duration_minutes INT NOT NULL CHECK (default_duration_minutes > 0),
  default_price_bif INT NOT NULL CHECK (default_price_bif >= 0),
  -- Suggested variants, e.g. [{"name":"Cheveux longs","duration_delta_minutes":30,"price_delta_bif":5000}].
  -- Kept as JSONB (not a child table) because this is seed/reference data with no
  -- FK integrity requirement of its own — real per-salon variants live in
  -- service_variants below, scoped to a real services row.
  default_variants JSONB NOT NULL DEFAULT '[]',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  -- Makes the seed script's ON CONFLICT (category_id, name) DO NOTHING an actual
  -- idempotency guarantee rather than a no-op arbiter-less clause.
  UNIQUE (category_id, name)
);

CREATE INDEX IF NOT EXISTS idx_service_templates_category
  ON public.service_templates (category_id) WHERE deleted_at IS NULL;

ALTER TABLE public.service_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_templates_public_select" ON public.service_templates
  FOR SELECT USING (deleted_at IS NULL AND is_active = true);

CREATE TRIGGER service_templates_updated_at
  BEFORE UPDATE ON public.service_templates
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 3. services — ADDITIVE ONLY. Existing columns, rows, RLS, indexes, triggers
-- untouched. Both new columns are nullable so every existing INSERT/UPDATE in
-- the Flutter app keeps working unmodified.
ALTER TABLE public.services
  ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES public.categories(id),
  ADD COLUMN IF NOT EXISTS source_template_id UUID REFERENCES public.service_templates(id);

CREATE INDEX IF NOT EXISTS idx_services_category_id
  ON public.services (category_id) WHERE deleted_at IS NULL;

-- 4. service_variants — REAL per-salon-service variants (e.g. "Cheveux longs" on
-- a specific owner's actual service). Distinct from service_templates.default_variants,
-- which is only suggested/seed data.
CREATE TABLE IF NOT EXISTS public.service_variants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  duration_delta_minutes INT NOT NULL DEFAULT 0,
  price_delta_bif INT NOT NULL DEFAULT 0,
  sort_order INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_service_variants_service
  ON public.service_variants (service_id) WHERE deleted_at IS NULL;

ALTER TABLE public.service_variants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_variants_owner_manager_manage" ON public.service_variants
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.services s
      WHERE s.id = service_variants.service_id
        AND (public.has_role(auth.uid(), 'owner', s.salon_id)
             OR public.has_role(auth.uid(), 'manager', s.salon_id))
    )
  );

CREATE POLICY "service_variants_public_select" ON public.service_variants
  FOR SELECT USING (
    deleted_at IS NULL AND is_active = true
    AND EXISTS (
      SELECT 1 FROM public.services s
      WHERE s.id = service_variants.service_id
        AND s.deleted_at IS NULL AND s.is_active = true
    )
  );

CREATE TRIGGER service_variants_updated_at
  BEFORE UPDATE ON public.service_variants
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- 5. service_tags — free-form search/filter tags on a real service
-- (e.g. "sans-rendez-vous", "vegan", "express").
CREATE TABLE IF NOT EXISTS public.service_tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  tag TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  UNIQUE (service_id, tag)
);

CREATE INDEX IF NOT EXISTS idx_service_tags_service
  ON public.service_tags (service_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_service_tags_tag_trgm
  ON public.service_tags USING GIN (tag gin_trgm_ops) WHERE deleted_at IS NULL;

ALTER TABLE public.service_tags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_tags_owner_manager_manage" ON public.service_tags
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.services s
      WHERE s.id = service_tags.service_id
        AND (public.has_role(auth.uid(), 'owner', s.salon_id)
             OR public.has_role(auth.uid(), 'manager', s.salon_id))
    )
  );

CREATE POLICY "service_tags_public_select" ON public.service_tags
  FOR SELECT USING (
    deleted_at IS NULL
    AND EXISTS (
      SELECT 1 FROM public.services s
      WHERE s.id = service_tags.service_id
        AND s.deleted_at IS NULL AND s.is_active = true
    )
  );

-- 6. service_filters — structured facet key/value pairs for the discovery screen's
-- filter UI (e.g. filter_key='duration_band', filter_value='30-60min').
CREATE TABLE IF NOT EXISTS public.service_filters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
  filter_key TEXT NOT NULL,
  filter_value TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  UNIQUE (service_id, filter_key, filter_value)
);

CREATE INDEX IF NOT EXISTS idx_service_filters_service
  ON public.service_filters (service_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_service_filters_lookup
  ON public.service_filters (filter_key, filter_value) WHERE deleted_at IS NULL;

ALTER TABLE public.service_filters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_filters_owner_manager_manage" ON public.service_filters
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.services s
      WHERE s.id = service_filters.service_id
        AND (public.has_role(auth.uid(), 'owner', s.salon_id)
             OR public.has_role(auth.uid(), 'manager', s.salon_id))
    )
  );

CREATE POLICY "service_filters_public_select" ON public.service_filters
  FOR SELECT USING (
    deleted_at IS NULL
    AND EXISTS (
      SELECT 1 FROM public.services s
      WHERE s.id = service_filters.service_id
        AND s.deleted_at IS NULL AND s.is_active = true
    )
  );
