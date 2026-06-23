-- ================================================================
-- KYNZA — Migration 002 — Security hardening
-- 1. Pin search_path on SECURITY DEFINER functions (Postgres/Supabase
--    best practice: prevents search_path hijacking even though all
--    object references below are already schema-qualified).
-- 2. Add RLS policies for salons and activity_logs, which were left
--    with RLS enabled and zero policies in the foundation migration
--    (default-deny: completely inaccessible from anon/authenticated).
-- ================================================================

-- 1. handle_new_user — re-create with pinned search_path
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
    email_verified = NEW.email_confirmed_at IS NOT NULL,
    updated_at = NOW();
  RETURN NEW;
END; $$;

-- 2. custom_access_token_hook — re-create with pinned search_path
CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE claims jsonb; rec record;
BEGIN
  SELECT u.role, u.salon_id, u.preferred_currency,
         u.country_code, u.email, u.auth_provider
  INTO rec
  FROM public.users u
  WHERE u.id = (event->>'user_id')::uuid LIMIT 1;
  claims := event->'claims';
  claims := jsonb_set(claims,'{role}',to_jsonb(COALESCE(rec.role,'client')));
  claims := jsonb_set(claims,'{salon_id}',to_jsonb(rec.salon_id::text));
  claims := jsonb_set(claims,'{preferred_currency}',to_jsonb(COALESCE(rec.preferred_currency,'BIF')));
  claims := jsonb_set(claims,'{country_code}',to_jsonb(COALESCE(rec.country_code,'BI')));
  RETURN jsonb_set(event,'{claims}',claims);
END; $$;

REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM authenticated, anon, public;
REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook(jsonb) FROM authenticated, anon, public;

-- 3. RLS policies — salons
-- Public discovery: anyone (including anon, for browsing before signup)
-- can see salons that are online and not soft-deleted.
CREATE POLICY "salons_public_select" ON public.salons
  FOR SELECT USING (is_online = true AND deleted_at IS NULL);

-- Members (any role) can always see their own salon, even offline.
CREATE POLICY "salons_member_select" ON public.salons
  FOR SELECT USING (
    id IN (SELECT salon_id FROM public.users WHERE id = auth.uid())
  );

-- Any authenticated user can create a salon for themselves as owner.
CREATE POLICY "salons_owner_insert" ON public.salons
  FOR INSERT WITH CHECK (owner_id = auth.uid());

-- Owner or manager of the salon can update it.
CREATE POLICY "salons_owner_manager_update" ON public.salons
  FOR UPDATE USING (
    id IN (
      SELECT salon_id FROM public.users
      WHERE id = auth.uid() AND role IN ('owner','manager')
    )
  );

-- No DELETE policy: salons are soft-deleted via the deleted_at column.

-- 4. RLS policies — activity_logs (append-only audit trail)
-- Members can log their own actions within their own salon.
CREATE POLICY "activity_logs_member_insert" ON public.activity_logs
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    AND salon_id IN (SELECT salon_id FROM public.users WHERE id = auth.uid())
  );

-- Only owner/manager of the salon can read its audit trail.
CREATE POLICY "activity_logs_owner_manager_select" ON public.activity_logs
  FOR SELECT USING (
    salon_id IN (
      SELECT salon_id FROM public.users
      WHERE id = auth.uid() AND role IN ('owner','manager')
    )
  );

-- No UPDATE/DELETE policy: audit trail is immutable by design.