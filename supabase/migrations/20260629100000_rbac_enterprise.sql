-- ================================================================
-- KYNZA — Enterprise Foundation V2 — Phase 1.1 — Granular RBAC layer
--
-- Additive on top of the existing role system (owner/manager/staff/
-- client stay the source of truth on public.users.role — untouched).
-- This adds an optional permission-group layer so an Owner can grant
-- specific staff/manager accounts narrower or wider capabilities than
-- their base role without inventing new roles.
--
-- Resolution order in check_permission(): owner (always TRUE) →
-- direct user override (grant/revoke) → permission group membership
-- → default FALSE. Result cached 15 min in
-- user_effective_permissions_cache, mirrored client-side in Hive.
--
-- `resource` is NOT NULL DEFAULT '' (not nullable) on every table that
-- carries it — a nullable resource would make the UNIQUE constraints
-- on permission_definitions / user_effective_permissions_cache
-- ineffective, since Postgres treats every NULL as distinct from
-- every other NULL (ON CONFLICT would silently stop deduplicating and
-- the cache would grow one row per check instead of upserting).
-- ================================================================

-- 1. Permission catalog (global, not salon-scoped — KYNZA-defined).
CREATE TABLE IF NOT EXISTS public.permission_definitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature TEXT NOT NULL,
  action TEXT NOT NULL,
  resource TEXT NOT NULL DEFAULT '',
  label TEXT NOT NULL,
  description TEXT,
  risk_level TEXT NOT NULL DEFAULT 'low'
    CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
  UNIQUE (feature, action, resource)
);

ALTER TABLE public.permission_definitions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "permission_definitions_read_all" ON public.permission_definitions
  FOR SELECT USING (auth.role() = 'authenticated');

INSERT INTO public.permission_definitions (feature, action, resource, label, risk_level) VALUES
  ('bookings', 'view', 'all', 'Voir tous les RDV', 'low'),
  ('bookings', 'view', 'own', 'Voir ses RDV uniquement', 'low'),
  ('bookings', 'create', 'all', 'Créer un RDV', 'low'),
  ('bookings', 'edit', 'all', 'Modifier un RDV', 'medium'),
  ('bookings', 'cancel', 'all', 'Annuler un RDV', 'medium'),
  ('bookings', 'mark_no_show', 'all', 'Marquer no-show', 'medium'),
  ('staff', 'view', 'all', 'Voir l''équipe', 'low'),
  ('staff', 'manage', 'all', 'Gérer l''équipe', 'high'),
  ('staff', 'view_commissions', 'own', 'Voir ses commissions', 'low'),
  ('staff', 'view_commissions', 'all', 'Voir commissions équipe', 'high'),
  ('analytics', 'view', 'basic', 'Voir stats basiques', 'low'),
  ('analytics', 'view', 'advanced', 'Voir analytics avancés', 'medium'),
  ('analytics', 'export', 'all', 'Exporter les données', 'high'),
  ('billing', 'view', 'all', 'Voir la facturation', 'high'),
  ('billing', 'manage', 'all', 'Gérer abonnement', 'critical'),
  ('loyalty', 'view', 'all', 'Voir fidélité', 'low'),
  ('loyalty', 'stamp', 'all', 'Tamponner carte fidélité', 'medium'),
  ('marketing', 'view', 'all', 'Voir marketing', 'low'),
  ('marketing', 'manage', 'all', 'Gérer promotions', 'medium'),
  ('reviews', 'view', 'all', 'Voir les avis', 'low'),
  ('reviews', 'respond', 'all', 'Répondre aux avis', 'medium'),
  ('settings', 'view', 'all', 'Voir les paramètres', 'low'),
  ('settings', 'manage', 'all', 'Modifier les paramètres', 'critical')
ON CONFLICT (feature, action, resource) DO NOTHING;

-- 2. Permission groups — Owner-defined bundles of permissions, scoped
-- to a salon. base_role mirrors public.users.role's CHECK values.
CREATE TABLE IF NOT EXISTS public.permission_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  base_role TEXT NOT NULL CHECK (base_role IN ('owner', 'manager', 'staff', 'client')),
  is_system BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  UNIQUE (salon_id, name)
);

CREATE INDEX IF NOT EXISTS idx_permission_groups_salon
  ON public.permission_groups(salon_id) WHERE deleted_at IS NULL;

ALTER TABLE public.permission_groups ENABLE ROW LEVEL SECURITY;
CREATE POLICY "permission_groups_owner" ON public.permission_groups
  FOR ALL USING (public.has_role(auth.uid(), 'owner', salon_id));

-- 3. Permissions granted to a group.
CREATE TABLE IF NOT EXISTS public.permission_group_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.permission_groups(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES public.permission_definitions(id) ON DELETE CASCADE,
  granted BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (group_id, permission_id)
);

CREATE INDEX IF NOT EXISTS idx_permission_group_permissions_group
  ON public.permission_group_permissions(group_id);

ALTER TABLE public.permission_group_permissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "permission_group_permissions_owner" ON public.permission_group_permissions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.permission_groups pg
      WHERE pg.id = group_id AND public.has_role(auth.uid(), 'owner', pg.salon_id)
    )
  );

-- 4. User → group assignment (a user may belong to several groups;
-- effective permission is the OR of every group + override below).
CREATE TABLE IF NOT EXISTS public.user_permission_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  group_id UUID NOT NULL REFERENCES public.permission_groups(id) ON DELETE CASCADE,
  granted_by UUID REFERENCES public.users(id),
  granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  UNIQUE (salon_id, user_id, group_id)
);

CREATE INDEX IF NOT EXISTS idx_user_permission_groups_user
  ON public.user_permission_groups(salon_id, user_id) WHERE deleted_at IS NULL;

ALTER TABLE public.user_permission_groups ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_permission_groups_owner" ON public.user_permission_groups
  FOR ALL USING (public.has_role(auth.uid(), 'owner', salon_id));

-- 5. Direct per-user override (grant or revoke a single permission,
-- bypassing group membership — highest priority after the owner
-- always-allow shortcut).
CREATE TABLE IF NOT EXISTS public.user_permission_overrides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES public.permission_definitions(id) ON DELETE CASCADE,
  granted BOOLEAN NOT NULL,
  reason TEXT,
  granted_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  UNIQUE (salon_id, user_id, permission_id)
);

CREATE INDEX IF NOT EXISTS idx_user_permission_overrides_user
  ON public.user_permission_overrides(salon_id, user_id) WHERE deleted_at IS NULL;

ALTER TABLE public.user_permission_overrides ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_permission_overrides_owner" ON public.user_permission_overrides
  FOR ALL USING (public.has_role(auth.uid(), 'owner', salon_id));

-- 6. Materialized 15-minute cache of resolved permission checks.
CREATE TABLE IF NOT EXISTS public.user_effective_permissions_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  feature TEXT NOT NULL,
  action TEXT NOT NULL,
  resource TEXT NOT NULL DEFAULT '',
  has_permission BOOLEAN NOT NULL,
  computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '15 minutes'),
  UNIQUE (salon_id, user_id, feature, action, resource)
);

-- Plain (non-partial) index: a partial index predicate on NOW() is
-- rejected by Postgres (`functions in index predicate must be
-- IMMUTABLE`) — the equality columns alone are enough since the
-- expires_at filter happens in the function's WHERE clause, not here.
CREATE INDEX IF NOT EXISTS idx_user_effective_permissions_cache_lookup
  ON public.user_effective_permissions_cache(salon_id, user_id, feature, action, expires_at);

ALTER TABLE public.user_effective_permissions_cache ENABLE ROW LEVEL SECURITY;
CREATE POLICY "permission_cache_self_or_owner" ON public.user_effective_permissions_cache
  FOR SELECT USING (
    user_id = auth.uid() OR public.has_role(auth.uid(), 'owner', salon_id)
  );
-- No INSERT/UPDATE policy for authenticated/anon — only check_permission()
-- (SECURITY DEFINER) writes this table.

-- 7. check_permission() — the single entry point Flutter calls via
-- supabase.rpc(). Guards against an authenticated caller probing
-- another user's permissions or another salon's data: self-checks are
-- always allowed, checking someone else requires the caller to be
-- owner or manager of that same salon (mirrors who can already see a
-- teammate's profile elsewhere in the app).
CREATE OR REPLACE FUNCTION public.check_permission(
  p_user_id UUID,
  p_salon_id UUID,
  p_feature TEXT,
  p_action TEXT,
  p_resource TEXT DEFAULT ''
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  v_caller_salon_id UUID;
  v_role TEXT;
  v_has_perm BOOLEAN;
  v_cached BOOLEAN;
BEGIN
  IF auth.role() = 'authenticated' THEN
    SELECT salon_id INTO v_caller_salon_id
    FROM public.users WHERE id = auth.uid() AND deleted_at IS NULL;

    IF p_salon_id IS DISTINCT FROM v_caller_salon_id THEN
      RAISE EXCEPTION 'salon_id mismatch';
    END IF;

    IF p_user_id <> auth.uid()
       AND NOT (public.has_role(auth.uid(), 'owner', v_caller_salon_id)
                OR public.has_role(auth.uid(), 'manager', v_caller_salon_id)) THEN
      RAISE EXCEPTION 'not authorized to check another user''s permissions';
    END IF;
  END IF;

  SELECT has_permission INTO v_cached
  FROM public.user_effective_permissions_cache
  WHERE salon_id = p_salon_id AND user_id = p_user_id
    AND feature = p_feature AND action = p_action AND resource = p_resource
    AND expires_at > NOW();
  IF FOUND THEN RETURN v_cached; END IF;

  SELECT role INTO v_role FROM public.users WHERE id = p_user_id AND deleted_at IS NULL;
  IF v_role IS NULL THEN RETURN FALSE; END IF;

  IF v_role = 'owner' THEN
    v_has_perm := TRUE;
  ELSE
    SELECT upo.granted INTO v_has_perm
    FROM public.user_permission_overrides upo
    JOIN public.permission_definitions pd ON pd.id = upo.permission_id
    WHERE upo.salon_id = p_salon_id AND upo.user_id = p_user_id
      AND pd.feature = p_feature AND pd.action = p_action AND pd.resource = p_resource
      AND (upo.expires_at IS NULL OR upo.expires_at > NOW())
      AND upo.deleted_at IS NULL
    LIMIT 1;

    IF NOT FOUND THEN
      SELECT bool_or(pgp.granted) INTO v_has_perm
      FROM public.user_permission_groups upg
      JOIN public.permission_group_permissions pgp ON pgp.group_id = upg.group_id
      JOIN public.permission_definitions pd ON pd.id = pgp.permission_id
      WHERE upg.salon_id = p_salon_id AND upg.user_id = p_user_id
        AND pd.feature = p_feature AND pd.action = p_action AND pd.resource = p_resource
        AND (upg.expires_at IS NULL OR upg.expires_at > NOW())
        AND upg.deleted_at IS NULL;

      v_has_perm := COALESCE(v_has_perm, FALSE);
    END IF;
  END IF;

  INSERT INTO public.user_effective_permissions_cache
    (salon_id, user_id, feature, action, resource, has_permission)
  VALUES (p_salon_id, p_user_id, p_feature, p_action, p_resource, v_has_perm)
  ON CONFLICT (salon_id, user_id, feature, action, resource)
  DO UPDATE SET has_permission = EXCLUDED.has_permission,
    computed_at = NOW(), expires_at = NOW() + INTERVAL '15 minutes';

  RETURN v_has_perm;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.check_permission(UUID, UUID, TEXT, TEXT, TEXT) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.check_permission(UUID, UUID, TEXT, TEXT, TEXT) TO authenticated;