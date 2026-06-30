-- Phase 4 — Evolution Platform
-- Sub-system 2: Maintenance Mode

CREATE TABLE IF NOT EXISTS public.maintenance_windows (
  id                 UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  title              TEXT        NOT NULL,
  message            TEXT        NOT NULL,
  starts_at          TIMESTAMPTZ NOT NULL,
  ends_at            TIMESTAMPTZ NOT NULL,
  affects_all        BOOLEAN     NOT NULL DEFAULT true,
  affected_salon_ids UUID[]      DEFAULT NULL,
  created_by         UUID        REFERENCES public.users(id),
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_maintenance_window_order CHECK (ends_at > starts_at)
);
ALTER TABLE public.maintenance_windows ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_maintenance_windows_active
  ON public.maintenance_windows (starts_at, ends_at);

-- Authenticated users read windows so the app can check if it's affected
CREATE POLICY "maintenance_windows_authenticated_select"
  ON public.maintenance_windows FOR SELECT TO authenticated USING (true);
-- Admin creates/updates via service_role (no authenticated INSERT policy)

-- ─── RPC: is_maintenance_active() ──────────────────────────────────────────
--
-- Always returns exactly 1 row.
-- is_active=true  → app should show MaintenanceScreen
-- is_active=false → no active maintenance

CREATE OR REPLACE FUNCTION public.is_maintenance_active()
RETURNS TABLE(
  is_active BOOLEAN,
  title     TEXT,
  message   TEXT,
  ends_at   TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY INVOKER
STABLE
AS $$
DECLARE
  v_salon_id UUID;
BEGIN
  SELECT u.salon_id INTO v_salon_id
  FROM public.users u WHERE u.id = auth.uid() LIMIT 1;

  RETURN QUERY
  SELECT
    true            AS is_active,
    mw.title        AS title,
    mw.message      AS message,
    mw.ends_at      AS ends_at
  FROM public.maintenance_windows mw
  WHERE now() BETWEEN mw.starts_at AND mw.ends_at
    AND (
      mw.affects_all = true
      OR (v_salon_id IS NOT NULL AND v_salon_id = ANY(mw.affected_salon_ids))
    )
  ORDER BY mw.ends_at ASC
  LIMIT 1;

  -- FOUND is true if RETURN QUERY above returned at least 1 row
  IF NOT FOUND THEN
    RETURN QUERY SELECT false, NULL::TEXT, NULL::TEXT, NULL::TIMESTAMPTZ;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.is_maintenance_active() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.is_maintenance_active() FROM anon;