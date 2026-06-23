-- ================================================================
-- KYNZA — Migration 004 — Allow the one-time onboarding role choice
-- Migration 003 made `role` fully immutable via the client API. That is
-- correct to prevent privilege escalation post-onboarding, but it also
-- blocks the legitimate complete-profile flow: a brand new user must be
-- able to choose client/staff/owner exactly once (the
-- profile_completed: false -> true transition), after which the column
-- becomes immutable again exactly as before.
-- 'manager' is intentionally excluded — that role is only ever granted
-- via Owner invitation (Phase 2), never self-selected.
-- ================================================================

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
      IF NOT (
        OLD.profile_completed = false
        AND NEW.profile_completed = true
        AND NEW.role IN ('client', 'staff', 'owner')
      ) THEN
        RAISE EXCEPTION 'role is immutable via client API';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END; $$;

DROP POLICY IF EXISTS "users_self_update_safe" ON public.users;
CREATE POLICY "users_self_update_safe" ON public.users
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND salon_id IS NOT DISTINCT FROM (
      SELECT salon_id FROM public.users WHERE id = auth.uid()
    )
    AND email_verified IS NOT DISTINCT FROM (
      SELECT email_verified FROM public.users WHERE id = auth.uid()
    )
    AND (
      role IS NOT DISTINCT FROM (SELECT role FROM public.users WHERE id = auth.uid())
      OR (
        (SELECT profile_completed FROM public.users WHERE id = auth.uid()) = false
        AND profile_completed = true
        AND role IN ('client', 'staff', 'owner')
      )
    )
  );