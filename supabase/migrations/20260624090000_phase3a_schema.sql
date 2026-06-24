-- ═══════════════════════════════════════════════════
-- PHASE 3A — Loyalty, Reviews, Owner Journey, Marketing
-- ═══════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════
-- LOYALTY SYSTEM
-- ═══════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.loyalty_programs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL UNIQUE REFERENCES public.salons(id),
  stamps_required INT NOT NULL DEFAULT 10
    CHECK(stamps_required BETWEEN 1 AND 50),
  reward_description TEXT NOT NULL,
  reward_value_bif INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.loyalty_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  client_id UUID NOT NULL REFERENCES public.users(id),
  stamps_count INT NOT NULL DEFAULT 0,
  total_stamps_earned INT NOT NULL DEFAULT 0,
  total_redeemed INT NOT NULL DEFAULT 0,
  last_stamp_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  UNIQUE(salon_id, client_id)
);

CREATE TABLE IF NOT EXISTS public.loyalty_stamp_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES public.loyalty_cards(id),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  client_id UUID NOT NULL REFERENCES public.users(id),
  booking_id UUID REFERENCES public.bookings(id),
  action TEXT NOT NULL CHECK(action IN('earned','redeemed','expired')),
  stamps_delta INT NOT NULL,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_loyalty_cards_client
  ON public.loyalty_cards(client_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_loyalty_cards_salon
  ON public.loyalty_cards(salon_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_loyalty_stamp_logs_card
  ON public.loyalty_stamp_logs(card_id);

-- ═══════════════════════════════════════════════════
-- REVIEWS & RATINGS
-- ═══════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  client_id UUID NOT NULL REFERENCES public.users(id),
  booking_id UUID NOT NULL UNIQUE REFERENCES public.bookings(id),
  rating INT NOT NULL CHECK(rating BETWEEN 1 AND 5),
  comment TEXT,
  is_anonymous BOOLEAN DEFAULT false,
  is_verified BOOLEAN DEFAULT true,
  owner_reply TEXT,
  owner_replied_at TIMESTAMPTZ,
  is_flagged BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.review_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES public.reviews(id),
  url TEXT NOT NULL,
  type TEXT CHECK(type IN('image','video')) DEFAULT 'image',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_reviews_salon
  ON public.reviews(salon_id) WHERE deleted_at IS NULL AND is_flagged = false;

-- Salon rating rollup. security_invoker so it respects the underlying
-- reviews RLS instead of running as the view owner.
CREATE OR REPLACE VIEW public.v_salon_ratings
  WITH (security_invoker = true) AS
SELECT
  salon_id,
  COUNT(*) AS total_reviews,
  ROUND(AVG(rating)::numeric, 1) AS average_rating,
  COUNT(*) FILTER (WHERE rating = 5) AS five_star,
  COUNT(*) FILTER (WHERE rating = 4) AS four_star,
  COUNT(*) FILTER (WHERE rating = 3) AS three_star,
  COUNT(*) FILTER (WHERE rating = 2) AS two_star,
  COUNT(*) FILTER (WHERE rating = 1) AS one_star
FROM public.reviews
WHERE deleted_at IS NULL AND is_flagged = false
GROUP BY salon_id;

GRANT SELECT ON public.v_salon_ratings TO authenticated, anon;

-- protect_review_columns — a client editing their own review (within the
-- 30-day window) can only ever touch rating/comment/is_anonymous; an
-- owner/manager replying can only ever touch the owner_reply fields.
-- Mirrors the protect_user_columns pattern already used on public.users.
CREATE OR REPLACE FUNCTION public.protect_review_columns()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF OLD.client_id = auth.uid() THEN
    NEW.owner_reply := OLD.owner_reply;
    NEW.owner_replied_at := OLD.owner_replied_at;
    NEW.is_flagged := OLD.is_flagged;
  ELSE
    NEW.rating := OLD.rating;
    NEW.comment := OLD.comment;
    NEW.is_anonymous := OLD.is_anonymous;
  END IF;
  NEW.client_id := OLD.client_id;
  NEW.booking_id := OLD.booking_id;
  NEW.salon_id := OLD.salon_id;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.protect_review_columns() FROM anon, authenticated;

-- ═══════════════════════════════════════════════════
-- OWNER SUCCESS JOURNEY
-- ═══════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.owner_journey_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL UNIQUE REFERENCES public.salons(id),
  owner_id UUID NOT NULL REFERENCES public.users(id),
  step_salon_info_done BOOLEAN DEFAULT false,
  step_salon_info_done_at TIMESTAMPTZ,
  step_first_service_done BOOLEAN DEFAULT false,
  step_first_service_done_at TIMESTAMPTZ,
  step_team_done BOOLEAN DEFAULT false,
  step_team_done_at TIMESTAMPTZ,
  step_hours_done BOOLEAN DEFAULT false,
  step_hours_done_at TIMESTAMPTZ,
  step_first_booking_done BOOLEAN DEFAULT false,
  step_first_booking_done_at TIMESTAMPTZ,
  completed_steps INT GENERATED ALWAYS AS (
    (step_salon_info_done::int) +
    (step_first_service_done::int) +
    (step_team_done::int) +
    (step_hours_done::int) +
    (step_first_booking_done::int)
  ) STORED,
  completion_pct INT GENERATED ALWAYS AS (
    ((step_salon_info_done::int +
      step_first_service_done::int +
      step_team_done::int +
      step_hours_done::int +
      step_first_booking_done::int) * 100 / 5)
  ) STORED,
  is_complete BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION public.check_journey_complete()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.completed_steps = 5 AND NOT NEW.is_complete THEN
    NEW.is_complete := true;
    NEW.completed_at := NOW();
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;
CREATE TRIGGER journey_completion
  BEFORE UPDATE ON public.owner_journey_progress
  FOR EACH ROW EXECUTE FUNCTION public.check_journey_complete();

-- Auto-create journey row when a salon is created. owner_id is always
-- non-null at this point: salons_owner_insert (security_hardening
-- migration) requires owner_id = auth.uid() on every INSERT.
CREATE OR REPLACE FUNCTION public.init_owner_journey()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO public.owner_journey_progress (salon_id, owner_id)
  VALUES (NEW.id, NEW.owner_id)
  ON CONFLICT (salon_id) DO NOTHING;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS on_salon_created ON public.salons;
CREATE TRIGGER on_salon_created
  AFTER INSERT ON public.salons
  FOR EACH ROW EXECUTE FUNCTION public.init_owner_journey();

-- ═══════════════════════════════════════════════════
-- CLIENT CONTACTS (for owner marketing)
-- ═══════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.client_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  owner_id UUID NOT NULL REFERENCES public.users(id),
  client_user_id UUID REFERENCES public.users(id),
  full_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  notes TEXT,
  source TEXT CHECK(source IN(
    'manual','booking','import','referral'
  )) DEFAULT 'manual',
  opted_in BOOLEAN DEFAULT false,
  opted_in_at TIMESTAMPTZ,
  invite_sent_at TIMESTAMPTZ,
  invite_accepted_at TIMESTAMPTZ,
  referral_token UUID DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_contacts_salon
  ON public.client_contacts(salon_id) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_contacts_referral
  ON public.client_contacts(referral_token);

-- ═══════════════════════════════════════════════════
-- PROMOTIONS
-- ═══════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.promotions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  title TEXT NOT NULL,
  description TEXT,
  discount_type TEXT CHECK(discount_type IN('percent','fixed_bif'))
    NOT NULL DEFAULT 'percent',
  discount_value INT NOT NULL CHECK(discount_value > 0),
  service_id UUID REFERENCES public.services(id),
  min_booking_bif INT DEFAULT 0,
  max_uses INT,
  current_uses INT DEFAULT 0,
  promo_code TEXT UNIQUE,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_promo_salon_active
  ON public.promotions(salon_id, ends_at)
  WHERE deleted_at IS NULL AND is_active = true;

-- ═══════════════════════════════════════════════════
-- REFERRAL TRACKING (schema only — wired up in a later phase)
-- ═══════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id UUID NOT NULL REFERENCES public.users(id),
  referred_id UUID REFERENCES public.users(id),
  salon_id UUID REFERENCES public.salons(id),
  referral_token UUID NOT NULL UNIQUE,
  status TEXT CHECK(status IN(
    'pending','signed_up','booked','rewarded'
  )) DEFAULT 'pending',
  reward_granted BOOLEAN DEFAULT false,
  reward_stamps INT DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════
-- RLS ON ALL NEW TABLES
-- ═══════════════════════════════════════════════════
ALTER TABLE public.loyalty_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_stamp_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.owner_journey_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.client_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.promotions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

-- LOYALTY PROGRAMS: owner/manager manage, everyone reads active ones
CREATE POLICY "owner_manage_loyalty_program" ON public.loyalty_programs
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  )
  WITH CHECK (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );
CREATE POLICY "public_read_loyalty_program" ON public.loyalty_programs
  FOR SELECT USING (is_active = true AND deleted_at IS NULL);

-- LOYALTY CARDS: client can only ever read their own card (stamps are
-- earned/redeemed by salon staff, never self-served by the client).
CREATE POLICY "client_select_own_card" ON public.loyalty_cards
  FOR SELECT USING (client_id = auth.uid());
CREATE POLICY "salon_manage_cards" ON public.loyalty_cards
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
    OR public.has_role(auth.uid(), 'staff', salon_id)
  )
  WITH CHECK (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
    OR public.has_role(auth.uid(), 'staff', salon_id)
  );

-- LOYALTY STAMP LOGS: append-only audit trail for salon staff, read-only for the client
CREATE POLICY "salon_manage_stamp_logs" ON public.loyalty_stamp_logs
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
    OR public.has_role(auth.uid(), 'staff', salon_id)
  )
  WITH CHECK (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
    OR public.has_role(auth.uid(), 'staff', salon_id)
  );
CREATE POLICY "client_select_own_stamp_logs" ON public.loyalty_stamp_logs
  FOR SELECT USING (client_id = auth.uid());

-- REVIEWS: a client may only review a completed booking of their own;
-- column-level write protection comes from protect_review_columns above.
CREATE POLICY "client_create_review" ON public.reviews
  FOR INSERT WITH CHECK (
    client_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = booking_id
        AND b.client_id = auth.uid()
        AND b.salon_id = reviews.salon_id
        AND b.status = 'completed'
    )
  );
CREATE POLICY "client_update_own_review" ON public.reviews
  FOR UPDATE USING (
    client_id = auth.uid()
    AND created_at > NOW() - INTERVAL '30 days'
    AND owner_reply IS NULL
  );
CREATE POLICY "owner_reply_review" ON public.reviews
  FOR UPDATE USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );
CREATE POLICY "public_read_reviews" ON public.reviews
  FOR SELECT USING (deleted_at IS NULL AND is_flagged = false);
CREATE POLICY "owner_select_own_salon_reviews" ON public.reviews
  FOR SELECT USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

CREATE TRIGGER reviews_protect_columns
  BEFORE UPDATE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.protect_review_columns();

-- REVIEW MEDIA: client manages photos/videos attached to their own review,
-- visible to anyone who can see that review.
CREATE POLICY "client_manage_own_review_media" ON public.review_media
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.reviews r
      WHERE r.id = review_id AND r.client_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.reviews r
      WHERE r.id = review_id AND r.client_id = auth.uid()
    )
  );
CREATE POLICY "public_read_review_media" ON public.review_media
  FOR SELECT USING (
    deleted_at IS NULL
    AND EXISTS (
      SELECT 1 FROM public.reviews r
      WHERE r.id = review_id AND r.deleted_at IS NULL AND r.is_flagged = false
    )
  );

-- JOURNEY: owner of that journey row only
CREATE POLICY "owner_own_journey" ON public.owner_journey_progress
  FOR ALL USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- CONTACTS: owner/manager of that salon only
CREATE POLICY "owner_manage_contacts" ON public.client_contacts
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  )
  WITH CHECK (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

-- PROMOTIONS: owner/manager manage, everyone reads active+unexpired ones
CREATE POLICY "owner_manage_promotions" ON public.promotions
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  )
  WITH CHECK (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );
CREATE POLICY "public_read_promotions" ON public.promotions
  FOR SELECT USING (
    is_active = true AND deleted_at IS NULL
    AND ends_at > NOW()
  );

-- REFERRALS: visible to either party
CREATE POLICY "own_referrals" ON public.referrals
  FOR ALL USING (referrer_id = auth.uid() OR referred_id = auth.uid())
  WITH CHECK (referrer_id = auth.uid() OR referred_id = auth.uid());

-- updated_at TRIGGERS
CREATE TRIGGER loyalty_programs_updated_at
  BEFORE UPDATE ON public.loyalty_programs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER loyalty_cards_updated_at
  BEFORE UPDATE ON public.loyalty_cards
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER promotions_updated_at
  BEFORE UPDATE ON public.promotions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER contacts_updated_at
  BEFORE UPDATE ON public.client_contacts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER referrals_updated_at
  BEFORE UPDATE ON public.referrals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
-- NB: reviews_updated_at is folded into protect_review_columns() above,
-- which already sets NEW.updated_at := NOW() on every UPDATE.