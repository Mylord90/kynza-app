-- ================================================================
-- KYNZA — Enterprise Foundation V2 — Phase 1.1 follow-up.
--
-- Found while verifying check_permission(): granting/revoking an
-- override or group permission did not take effect until the 15-min
-- cache entry naturally expired, because an earlier "default deny"
-- check had already cached FALSE for that exact key. An Owner
-- revoking access should not leave it live for up to 15 more minutes
-- (same instant-effect expectation as R20 session revocation) — so
-- invalidate the affected cache rows immediately on every write to
-- the tables that feed check_permission()'s resolution.
-- ================================================================

CREATE OR REPLACE FUNCTION public.invalidate_permission_cache_for_row()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  v_salon_id UUID;
  v_user_id UUID;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_salon_id := OLD.salon_id; v_user_id := OLD.user_id;
  ELSE
    v_salon_id := NEW.salon_id; v_user_id := NEW.user_id;
  END IF;
  DELETE FROM public.user_effective_permissions_cache
  WHERE salon_id = v_salon_id AND user_id = v_user_id;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS invalidate_cache_on_override_change ON public.user_permission_overrides;
CREATE TRIGGER invalidate_cache_on_override_change
  AFTER INSERT OR UPDATE OR DELETE ON public.user_permission_overrides
  FOR EACH ROW EXECUTE FUNCTION public.invalidate_permission_cache_for_row();

DROP TRIGGER IF EXISTS invalidate_cache_on_group_assignment_change ON public.user_permission_groups;
CREATE TRIGGER invalidate_cache_on_group_assignment_change
  AFTER INSERT OR UPDATE OR DELETE ON public.user_permission_groups
  FOR EACH ROW EXECUTE FUNCTION public.invalidate_permission_cache_for_row();

CREATE OR REPLACE FUNCTION public.invalidate_permission_cache_for_group()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  v_group_id UUID;
BEGIN
  v_group_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.group_id ELSE NEW.group_id END;
  DELETE FROM public.user_effective_permissions_cache c
  WHERE c.user_id IN (
    SELECT upg.user_id FROM public.user_permission_groups upg WHERE upg.group_id = v_group_id
  );
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS invalidate_cache_on_group_permission_change ON public.permission_group_permissions;
CREATE TRIGGER invalidate_cache_on_group_permission_change
  AFTER INSERT OR UPDATE OR DELETE ON public.permission_group_permissions
  FOR EACH ROW EXECUTE FUNCTION public.invalidate_permission_cache_for_group();