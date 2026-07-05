-- Master Plan Execution / Enterprise Final 100 CP2 — closes P2-8
-- (Master Inventory: `is_system_admin` has no documented grant/revoke/audit
-- mechanism — anyone with direct DB access can flip it with no trail).
--
-- DRAFT ONLY — not applied to production per Rule 8. Verified live against
-- kynza-dr-scratch (Enterprise Final 100 CP2).
--
-- Bootstrapping the very first system_admin still requires one direct
-- service-role UPDATE (unavoidable — there's no admin to call an admin-
-- gated RPC before one exists). Every subsequent grant/revoke should go
-- through these RPCs instead, which is what actually gets audited.

CREATE TABLE IF NOT EXISTS public.system_admin_audit (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  target_user_id UUID      NOT NULL REFERENCES public.users(id),
  action       TEXT        NOT NULL CHECK (action IN ('granted', 'revoked')),
  actor_id     UUID        REFERENCES public.users(id),
  reason       TEXT,
  occurred_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.system_admin_audit ENABLE ROW LEVEL SECURITY;
CREATE POLICY "system_admin_audit_admin_select" ON public.system_admin_audit
  FOR SELECT TO authenticated USING (public.has_system_admin(auth.uid()));
-- No INSERT/UPDATE/DELETE policy for any role — only the 2 SECURITY
-- DEFINER RPCs below ever write here, same deny-by-omission pattern as
-- reminder_dispatch_claims/platform_backup_jobs.

CREATE INDEX IF NOT EXISTS idx_system_admin_audit_target
  ON public.system_admin_audit(target_user_id, occurred_at DESC);

-- Both RPCs below write to `users.is_system_admin`, which
-- `protect_user_columns` (20260704120000) makes immutable whenever
-- `auth.role() = 'authenticated'` — and SECURITY DEFINER does NOT change
-- what `auth.role()` returns (that reads the calling session's JWT claim,
-- unaffected by function-ownership context), so without the transaction-
-- local flag below, this trigger would reject these RPCs' own UPDATE for
-- every real authenticated caller. Verified live, not assumed (see
-- Enterprise Final 100 CP2 report). `set_config(..., true)` is
-- transaction-scoped — it cannot leak into any other statement/session.
CREATE OR REPLACE FUNCTION public.protect_user_columns()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF auth.role() = 'authenticated' THEN
    IF NEW.salon_id IS DISTINCT FROM OLD.salon_id THEN
      RAISE EXCEPTION 'salon_id is immutable via client API';
    END IF;
    IF NEW.email_verified IS DISTINCT FROM OLD.email_verified THEN
      RAISE EXCEPTION 'email_verified is immutable via client API';
    END IF;
    IF NEW.reliability_score IS DISTINCT FROM OLD.reliability_score THEN
      RAISE EXCEPTION 'reliability_score is immutable via client API';
    END IF;
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'role is immutable via client API';
    END IF;
    IF NEW.is_system_admin IS DISTINCT FROM OLD.is_system_admin
       AND current_setting('app.system_admin_grant_rpc', true) IS DISTINCT FROM 'true' THEN
      RAISE EXCEPTION 'is_system_admin is immutable via client API';
    END IF;
  END IF;
  RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION public.grant_system_admin(
  p_target_user_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  PERFORM set_config('app.system_admin_grant_rpc', 'true', true);
  UPDATE public.users SET is_system_admin = true WHERE id = p_target_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  INSERT INTO public.system_admin_audit (target_user_id, action, actor_id, reason)
  VALUES (p_target_user_id, 'granted', auth.uid(), p_reason);
END;
$$;

CREATE OR REPLACE FUNCTION public.revoke_system_admin(
  p_target_user_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NOT public.has_system_admin(auth.uid()) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  PERFORM set_config('app.system_admin_grant_rpc', 'true', true);
  UPDATE public.users SET is_system_admin = false WHERE id = p_target_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user_not_found';
  END IF;

  INSERT INTO public.system_admin_audit (target_user_id, action, actor_id, reason)
  VALUES (p_target_user_id, 'revoked', auth.uid(), p_reason);
END;
$$;

REVOKE ALL ON FUNCTION public.grant_system_admin(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.grant_system_admin(UUID, TEXT) TO authenticated;
REVOKE ALL ON FUNCTION public.revoke_system_admin(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.revoke_system_admin(UUID, TEXT) TO authenticated;
