-- ================================================================
-- KYNZA — Migration 001 — Foundation Schema
-- Exécuter dans cet ordre exact
-- ================================================================

-- 1. Extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Fonction updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$ BEGIN
  NEW.updated_at = NOW(); RETURN NEW;
END; $$ LANGUAGE plpgsql;

-- 3. Table salons (tenant root)
CREATE TABLE IF NOT EXISTS public.salons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_id UUID,
  plan TEXT CHECK(plan IN('free','pro','premium')) DEFAULT 'free',
  plan_status TEXT CHECK(plan_status IN('active','grace_period','expired')) DEFAULT 'active',
  country_code TEXT NOT NULL DEFAULT 'BI',
  currency TEXT NOT NULL DEFAULT 'BIF',
  address TEXT,
  is_online BOOLEAN DEFAULT true,
  employees_count INT DEFAULT 0,
  monthly_bookings_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE TRIGGER salons_updated_at BEFORE UPDATE ON public.salons
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 4. Table users
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  salon_id UUID REFERENCES public.salons(id),
  role TEXT CHECK(role IN('owner','manager','staff','client')) DEFAULT 'client',
  full_name TEXT NOT NULL DEFAULT '',
  first_name TEXT,
  phone TEXT,
  email TEXT,
  email_verified BOOLEAN DEFAULT false,
  auth_provider TEXT DEFAULT 'email',
  profile_completed BOOLEAN DEFAULT false,
  avatar_url TEXT,
  reliability_score INT DEFAULT 100 CHECK(reliability_score BETWEEN 0 AND 100),
  country_code TEXT NOT NULL DEFAULT 'BI',
  preferred_currency TEXT NOT NULL DEFAULT 'BIF',
  locale TEXT NOT NULL DEFAULT 'fr_BI',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_users_salon ON public.users(salon_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE TRIGGER users_updated_at BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 5. Table activity_logs (append-only audit trail)
CREATE TABLE IF NOT EXISTS public.activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID REFERENCES public.salons(id),
  user_id UUID REFERENCES public.users(id),
  type_action TEXT NOT NULL,
  old_values JSONB,
  new_values JSONB,
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_logs_salon
  ON public.activity_logs(salon_id, created_at DESC);

-- 6. Activer RLS
ALTER TABLE public.salons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

-- 7. Politiques RLS de base
CREATE POLICY "users_self_select" ON public.users
  FOR SELECT USING (auth.uid() = id);

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
    AND role IS NOT DISTINCT FROM (
      SELECT role FROM public.users WHERE id = auth.uid()
    )
  );

-- 8. Trigger handle_new_user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
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

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 9. JWT Claims Hook
CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
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
