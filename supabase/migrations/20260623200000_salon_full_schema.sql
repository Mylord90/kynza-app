-- ================================================================
-- KYNZA — Migration 005 — Phase 2 / Subphase A — Salon full profile
-- 1. Extend public.salons with the full business-profile columns
--    needed by the onboarding wizard (slogan, location, media, hours).
-- 2. New tables: salon_media (portfolio), working_hours.
-- 3. Narrow, self-limiting exception in protect_user_columns() that
--    lets a brand-new owner set their OWN users.salon_id exactly once,
--    from NULL to a salon they own (mirrors the existing role
--    onboarding exception added in migration 004) — this is what lets
--    SalonCreationWizardScreen attach the owner to the salon they just
--    created without a dedicated Edge Function.
-- ================================================================

-- 1. salons — business profile columns
ALTER TABLE public.salons
  ADD COLUMN IF NOT EXISTS slogan TEXT,
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS province TEXT,
  ADD COLUMN IF NOT EXISTS commune TEXT,
  ADD COLUMN IF NOT EXISTS latitude DECIMAL(10,8),
  ADD COLUMN IF NOT EXISTS longitude DECIMAL(11,8),
  ADD COLUMN IF NOT EXISTS logo_url TEXT,
  ADD COLUMN IF NOT EXISTS cover_url TEXT,
  ADD COLUMN IF NOT EXISTS is_verified BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS social_facebook TEXT,
  ADD COLUMN IF NOT EXISTS social_instagram TEXT,
  ADD COLUMN IF NOT EXISTS social_tiktok TEXT,
  ADD COLUMN IF NOT EXISTS social_whatsapp TEXT;

-- 2. salon_media — portfolio (images/videos)
CREATE TABLE IF NOT EXISTS public.salon_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  url TEXT NOT NULL,
  type TEXT NOT NULL CHECK(type IN('image','video')) DEFAULT 'image',
  thumbnail_url TEXT,
  caption TEXT,
  display_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_salon_media_salon
  ON public.salon_media(salon_id, display_order)
  WHERE deleted_at IS NULL;

CREATE TRIGGER salon_media_updated_at BEFORE UPDATE ON public.salon_media
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 3. working_hours — 7 rows per salon (one per day_of_week)
CREATE TABLE IF NOT EXISTS public.working_hours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  day_of_week INT NOT NULL CHECK(day_of_week BETWEEN 0 AND 6),
  opens_at TIME,
  closes_at TIME,
  is_closed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  UNIQUE(salon_id, day_of_week)
);

CREATE TRIGGER working_hours_updated_at BEFORE UPDATE ON public.working_hours
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 4. RLS — salon_media
ALTER TABLE public.salon_media ENABLE ROW LEVEL SECURITY;

CREATE POLICY "salon_media_owner_manager_manage" ON public.salon_media
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

CREATE POLICY "salon_media_public_select" ON public.salon_media
  FOR SELECT USING (deleted_at IS NULL);

-- 5. RLS — working_hours
ALTER TABLE public.working_hours ENABLE ROW LEVEL SECURITY;

CREATE POLICY "working_hours_owner_manager_manage" ON public.working_hours
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

CREATE POLICY "working_hours_public_select" ON public.working_hours
  FOR SELECT USING (deleted_at IS NULL);

-- 6. protect_user_columns — add narrow salon_id onboarding exception.
-- Self-limiting: once OLD.salon_id is no longer NULL this branch never
-- matches again, exactly like the role exception in migration 004.
CREATE OR REPLACE FUNCTION public.protect_user_columns()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF auth.role() = 'authenticated' THEN
    IF NEW.salon_id IS DISTINCT FROM OLD.salon_id THEN
      IF NOT (
        OLD.salon_id IS NULL
        AND NEW.salon_id IS NOT NULL
        AND EXISTS (
          SELECT 1 FROM public.salons s
          WHERE s.id = NEW.salon_id AND s.owner_id = auth.uid()
        )
      ) THEN
        RAISE EXCEPTION 'salon_id is immutable via client API';
      END IF;
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

-- 7. users_self_update_safe — mirror the same exception in WITH CHECK
-- (defense in depth: RLS policy + trigger both enforce the same rule).
DROP POLICY IF EXISTS "users_self_update_safe" ON public.users;
CREATE POLICY "users_self_update_safe" ON public.users
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND (
      salon_id IS NOT DISTINCT FROM (SELECT salon_id FROM public.users WHERE id = auth.uid())
      OR (
        (SELECT salon_id FROM public.users WHERE id = auth.uid()) IS NULL
        AND salon_id IN (SELECT id FROM public.salons WHERE owner_id = auth.uid())
      )
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
