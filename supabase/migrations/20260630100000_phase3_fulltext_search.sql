-- ================================================================
-- PHASE 3 — Enterprise Data Platform
-- Sub-migration 1/4: Full-text search
--
-- Current search uses .ilike('%query%') — a leading wildcard defeats
-- every btree index and forces a sequential scan.  Two-pronged fix:
--
-- 1. pg_trgm + GIN indexes on the text columns the Flutter search
--    already queries (.ilike calls now hit the index automatically —
--    zero Flutter-side changes required).
--
-- 2. Generated tsvector columns + GIN indexes + search_salon_data() RPC
--    for language-aware ranked results when the search screen migrates
--    to the RPC path (Phase 3 follow-up or when the dataset grows large
--    enough for stemming to matter).
--
-- 'simple' text search config: preserves words as-is, no stemming.
-- Better than 'french' for a mix of French words and brand names
-- (e.g. "Salon Elégance", "BeautyGlow") that stemming would mangle.
-- ================================================================

-- ── 1. pg_trgm extension ──────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ── 2. GIN trigram indexes (speed up existing ILIKE queries) ──────
-- salons: name + description (searched together in _searchSalons)
CREATE INDEX IF NOT EXISTS idx_salons_name_trgm
  ON public.salons USING GIN (name gin_trgm_ops)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_salons_description_trgm
  ON public.salons USING GIN (description gin_trgm_ops)
  WHERE deleted_at IS NULL;

-- services: name (searched in _searchServices)
CREATE INDEX IF NOT EXISTS idx_services_name_trgm
  ON public.services USING GIN (name gin_trgm_ops)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_services_category_trgm
  ON public.services USING GIN (category gin_trgm_ops)
  WHERE deleted_at IS NULL;

-- ── 3. Generated tsvector columns (language-aware FTS) ────────────
-- salons: name + description + slogan + province
ALTER TABLE public.salons
  ADD COLUMN IF NOT EXISTS search_vector tsvector
    GENERATED ALWAYS AS (
      setweight(to_tsvector('simple', coalesce(name, '')), 'A')
      || setweight(to_tsvector('simple', coalesce(slogan, '')), 'B')
      || setweight(to_tsvector('simple', coalesce(description, '')), 'C')
      || setweight(to_tsvector('simple', coalesce(province, '')), 'D')
      || setweight(to_tsvector('simple', coalesce(commune, '')), 'D')
    ) STORED;

CREATE INDEX IF NOT EXISTS idx_salons_search_vector
  ON public.salons USING GIN (search_vector)
  WHERE deleted_at IS NULL;

-- services: name + description + category
ALTER TABLE public.services
  ADD COLUMN IF NOT EXISTS search_vector tsvector
    GENERATED ALWAYS AS (
      setweight(to_tsvector('simple', coalesce(name, '')), 'A')
      || setweight(to_tsvector('simple', coalesce(description, '')), 'B')
      || setweight(to_tsvector('simple', coalesce(category, '')), 'C')
    ) STORED;

CREATE INDEX IF NOT EXISTS idx_services_search_vector
  ON public.services USING GIN (search_vector)
  WHERE deleted_at IS NULL;

-- ── 4. search_salon_data() — unified FTS RPC ──────────────────────
-- Returns salons + services matching p_query, ranked by relevance.
-- p_type: 'salon' | 'service' | 'all' (default)
-- Uses SECURITY INVOKER so the caller's RLS on salons/services applies
-- (public SELECT on active salons/services — same as the existing search
-- screen's raw queries).
CREATE OR REPLACE FUNCTION public.search_salon_data(
  p_query    TEXT,
  p_type     TEXT  DEFAULT 'all',
  p_province TEXT  DEFAULT NULL,
  p_limit    INT   DEFAULT 30
)
RETURNS TABLE(
  id         UUID,
  result_type TEXT,
  title      TEXT,
  subtitle   TEXT,
  salon_id   UUID,
  price_bif  INT,
  image_url  TEXT,
  province   TEXT,
  rank       REAL
)
LANGUAGE sql SECURITY INVOKER STABLE
SET search_path = public, pg_temp
AS $$
  WITH tsq AS (
    SELECT CASE
      WHEN length(trim(p_query)) < 1 THEN NULL
      ELSE websearch_to_tsquery('simple', p_query)
    END AS q
  ),
  salons_cte AS (
    SELECT
      s.id,
      'salon'::TEXT          AS result_type,
      s.name                 AS title,
      s.province             AS subtitle,
      s.id                   AS salon_id,
      NULL::INT              AS price_bif,
      s.logo_url             AS image_url,
      s.province,
      CASE WHEN (SELECT q FROM tsq) IS NULL THEN 1.0
           ELSE ts_rank(s.search_vector, (SELECT q FROM tsq))
      END                    AS rank
    FROM public.salons s
    WHERE s.deleted_at IS NULL
      AND s.is_online = true
      AND (p_province IS NULL OR s.province = p_province)
      AND (
        (SELECT q FROM tsq) IS NULL
        OR s.search_vector @@ (SELECT q FROM tsq)
      )
  ),
  services_cte AS (
    SELECT
      sv.id,
      'service'::TEXT        AS result_type,
      sv.name                AS title,
      sl.name                AS subtitle,
      sv.salon_id,
      sv.price_bif,
      sl.logo_url            AS image_url,
      sl.province,
      CASE WHEN (SELECT q FROM tsq) IS NULL THEN 1.0
           ELSE ts_rank(sv.search_vector, (SELECT q FROM tsq))
      END                    AS rank
    FROM public.services sv
    JOIN public.salons sl ON sl.id = sv.salon_id
    WHERE sv.deleted_at IS NULL
      AND sv.is_active = true
      AND sl.deleted_at IS NULL
      AND sl.is_online = true
      AND (p_province IS NULL OR sl.province = p_province)
      AND (
        (SELECT q FROM tsq) IS NULL
        OR sv.search_vector @@ (SELECT q FROM tsq)
      )
  )
  SELECT * FROM (
    SELECT * FROM salons_cte  WHERE p_type IN ('all','salon')
    UNION ALL
    SELECT * FROM services_cte WHERE p_type IN ('all','service')
  ) combined
  ORDER BY rank DESC
  LIMIT LEAST(p_limit, 100);
$$;

REVOKE EXECUTE ON FUNCTION public.search_salon_data(TEXT, TEXT, TEXT, INT) FROM anon;
GRANT  EXECUTE ON FUNCTION public.search_salon_data(TEXT, TEXT, TEXT, INT) TO authenticated;