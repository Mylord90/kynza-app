-- ================================================================
-- KYNZA — Migration 003 — Users schema completion + RLS hardening
-- 1. Add missing `last_name` column + correct indexes on public.users
--    (unique partial index on email, composite role/salon_id index).
-- 2. has_role(uid, role, salon_id?) — SECURITY INVOKER helper used by
--    sensitive RLS policies (AGENT.md Section 7, item 3).
-- 3. protect_user_columns trigger — defense-in-depth: blocks direct
--    client UPDATE of salon_id/email_verified/reliability_score/role
--    even though users_self_update_safe already enforces this via
--    WITH CHECK (AGENT.md Section 7, item 1).
-- 4. sync_email_verified — dedicated trigger that is the only writer
--    of users.email_verified going forward; handle_new_user no longer
--    re-syncs it on UPDATE (AGENT.md Section 7, item 2).
-- 5. logs_self_insert_safe — replaces activity_logs_member_insert with
--    a strict whitelist of type_action values (AGENT.md Section 7,
--    item 4).
-- 6. has_role() wired into the existing owner/manager policies on
--    salons and activity_logs to remove the duplicated role-lookup
--    subquery.
-- ================================================================

-- 1. users schema completion
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS last_name TEXT;

DROP INDEX IF EXISTS idx_users_email;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email
  ON public.users(email) WHERE email IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_users_role_salon
  ON public.users(role, salon_id);

-- 2. has_role helper — SECURITY INVOKER, runs as the calling role so it
-- is safe to use directly inside RLS policies.
CREATE OR REPLACE FUNCTION public.has_role(_uid UUID, _role TEXT, _salon_id UUID DEFAULT NULL)
RETURNS BOOLEAN LANGUAGE sql SECURITY INVOKER STABLE SET search_path = public, pg_temp AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users u
    WHERE u.id = _uid
      AND u.role = _role
      AND u.deleted_at IS NULL
      AND (_salon_id IS NULL OR u.salon_id = _salon_id)
  );
$$;

-- 3. protect_user_columns — blocks direct client mutation of sensitive
-- columns. service_role (Edge Functions / admin tooling) bypasses this,
-- only the `authenticated` Postgres role is restricted.
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
  END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS users_protect_columns ON public.users;
CREATE TRIGGER users_protect_columns
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.protect_user_columns();

-- 4. sync_email_verified — sole writer of email_verified post-signup.
-- handle_new_user keeps setting the initial value on INSERT but no
-- longer re-syncs it on UPDATE.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  INSERT INTO public.users (
    id, email, full_name, first_name, role,
    auth_provider, email_verified,
    country_code, preferred_currency, locale,
    created_at, updated_at
  ) VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name',''),
    SPLIT_PART(COALESCE(NEW.raw_user_meta_data->>'full_name',''),' ',1),
    'client',
    COALESCE(NEW.app_metadata->>'provider','email'),
    NEW.email_confirmed_at IS NOT NULL,
    'BI','BIF','fr_BI',
    NOW(), NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = NOW();
  RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION public.sync_email_verified()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NEW.email_confirmed_at IS DISTINCT FROM OLD.email_confirmed_at THEN
    UPDATE public.users
    SET email_verified = NEW.email_confirmed_at IS NOT NULL,
        updated_at = NOW()
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS on_auth_user_email_verified ON auth.users;
CREATE TRIGGER on_auth_user_email_verified
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.sync_email_verified();

REVOKE EXECUTE ON FUNCTION public.protect_user_columns() FROM authenticated, anon, public;
REVOKE EXECUTE ON FUNCTION public.sync_email_verified() FROM authenticated, anon, public;

-- 5. logs_self_insert_safe — whitelist of allowed type_action values.
-- Append-only: still no UPDATE/DELETE policy exists on this table.
DROP POLICY IF EXISTS "activity_logs_member_insert" ON public.activity_logs;

CREATE POLICY "logs_self_insert_safe" ON public.activity_logs
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    AND salon_id IN (SELECT salon_id FROM public.users WHERE id = auth.uid())
    AND type_action IN (
      'user_login','user_logout','profile_updated','role_changed',
      'salon_updated','salon_status_changed',
      'staff_invited','staff_removed',
      'booking_created','booking_confirmed','booking_cancelled',
      'booking_completed','booking_no_show',
      'payment_completed','payment_failed','refund_initiated',
      'discount_applied'
    )
  );

-- 6. Rewire owner/manager policies through has_role()
DROP POLICY IF EXISTS "salons_owner_manager_update" ON public.salons;
CREATE POLICY "salons_owner_manager_update" ON public.salons
  FOR UPDATE USING (
    public.has_role(auth.uid(), 'owner', id) OR public.has_role(auth.uid(), 'manager', id)
  );

DROP POLICY IF EXISTS "activity_logs_owner_manager_select" ON public.activity_logs;
CREATE POLICY "activity_logs_owner_manager_select" ON public.activity_logs
  FOR SELECT USING (
    public.has_role(auth.uid(), 'owner', salon_id) OR public.has_role(auth.uid(), 'manager', salon_id)
  );