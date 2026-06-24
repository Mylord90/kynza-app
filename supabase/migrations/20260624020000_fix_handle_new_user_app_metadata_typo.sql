-- ================================================================
-- KYNZA — Migration 019 — Fix handle_new_user() referencing a
-- non-existent column, which silently failed EVERY signup since the
-- project's first migration.
--
-- Root cause: `NEW.app_metadata` is not a field of auth.users — the
-- actual column is `raw_app_meta_data`. Accessing a non-existent field
-- on a trigger's NEW record raises "record \"new\" has no field
-- \"app_metadata\"", aborting the whole transaction GoTrue runs to
-- create a user (auth.users insert + auth.identities insert), which
-- GoTrue then reports to the client as the generic "Database error
-- saving new user" (500). Confirmed via postgres_logs: zero rows ever
-- existed in auth.users or public.users in this project before this
-- fix — discovered while verifying Phase 2's E2E signup → booking flow.
-- ================================================================

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
    COALESCE(NEW.raw_app_meta_data->>'provider','email'),
    NEW.email_confirmed_at IS NOT NULL,
    'BI','BIF','fr_BI',
    NOW(), NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    updated_at = NOW();
  RETURN NEW;
END; $$;

DROP FUNCTION IF EXISTS public._debug_log_cleanup();
DROP TABLE IF EXISTS public._debug_log;
