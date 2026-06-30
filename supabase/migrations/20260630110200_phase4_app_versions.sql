-- Phase 4 — Evolution Platform
-- Sub-system 3: Version Manager (force-upgrade gate)

CREATE TABLE IF NOT EXISTS public.app_versions (
  id                  UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  platform            TEXT    NOT NULL CHECK (platform IN ('android', 'ios')),
  version_name        TEXT    NOT NULL,
  version_code        INT     NOT NULL,
  is_minimum_required BOOLEAN NOT NULL DEFAULT false,
  release_notes       TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (platform, version_code)
);
ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read (version check happens post-login)
CREATE POLICY "app_versions_authenticated_select"
  ON public.app_versions FOR SELECT TO authenticated USING (true);

-- ─── RPC: check_app_version(platform, version_code) ────────────────────────
--
-- Returns 1 row:
--   update_required=true  → ForceUpdateScreen (blocks all navigation)
--   update_recommended=true → soft nudge (non-blocking)
--   message → human-readable explanation

CREATE OR REPLACE FUNCTION public.check_app_version(
  p_platform     TEXT,
  p_version_code INT
)
RETURNS TABLE(
  update_required    BOOLEAN,
  update_recommended BOOLEAN,
  latest_version_name TEXT,
  latest_version_code INT,
  message             TEXT
)
LANGUAGE plpgsql
SECURITY INVOKER
STABLE
AS $$
DECLARE
  v_min_code    INT;
  v_latest_code INT;
  v_latest_name TEXT;
BEGIN
  SELECT av.version_code INTO v_min_code
  FROM public.app_versions av
  WHERE av.platform = p_platform AND av.is_minimum_required = true
  ORDER BY av.version_code DESC LIMIT 1;

  SELECT av.version_code, av.version_name INTO v_latest_code, v_latest_name
  FROM public.app_versions av
  WHERE av.platform = p_platform
  ORDER BY av.version_code DESC LIMIT 1;

  IF v_latest_code IS NULL THEN
    -- No version records — all versions allowed
    RETURN QUERY SELECT false, false, NULL::TEXT, NULL::INT, NULL::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT
    COALESCE(p_version_code < v_min_code,    false)           AS update_required,
    COALESCE(p_version_code < v_latest_code, false)           AS update_recommended,
    v_latest_name                                             AS latest_version_name,
    v_latest_code                                             AS latest_version_code,
    CASE
      WHEN COALESCE(p_version_code < v_min_code, false)
        THEN 'Cette version de l''application n''est plus supportée. Veuillez mettre à jour pour continuer.'
      WHEN COALESCE(p_version_code < v_latest_code, false)
        THEN 'Une nouvelle version est disponible. Mettez à jour pour profiter des dernières améliorations.'
      ELSE NULL::TEXT
    END                                                       AS message;
END;
$$;

GRANT EXECUTE ON FUNCTION public.check_app_version(TEXT, INT) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.check_app_version(TEXT, INT) FROM anon;

-- Seed initial version (mirrors pubspec.yaml: version 1.0.0+1)
INSERT INTO public.app_versions
  (platform, version_name, version_code, is_minimum_required, release_notes)
VALUES
  ('android', '1.0.0', 1, true, 'Version initiale KYNZA'),
  ('ios',     '1.0.0', 1, true, 'Version initiale KYNZA')
ON CONFLICT (platform, version_code) DO NOTHING;