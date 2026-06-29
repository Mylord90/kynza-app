-- ═══════════════════════════════════════════════════
-- PHASE 3B — Loyalty QR tokens
-- referrals/loyalty_cards/loyalty_programs already exist (Phase 3A) —
-- claim-referral and validate-qr Edge Functions read/write those directly.
-- ═══════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.loyalty_qr_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES public.loyalty_cards(id),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  client_id UUID NOT NULL REFERENCES public.users(id),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '10 minutes'),
  used_at TIMESTAMPTZ,
  used_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_loyalty_qr_tokens_card
  ON public.loyalty_qr_tokens(card_id);

ALTER TABLE public.loyalty_qr_tokens ENABLE ROW LEVEL SECURITY;

-- Client mints their own token, scoped to a card they actually own —
-- validate-qr (service_role) is the only thing that ever marks one used,
-- so no UPDATE policy is needed for the `authenticated` role here.
CREATE POLICY "client_insert_own_qr_token" ON public.loyalty_qr_tokens
  FOR INSERT WITH CHECK (
    client_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.loyalty_cards lc
      WHERE lc.id = card_id
        AND lc.client_id = auth.uid()
        AND lc.salon_id = salon_id
    )
  );

CREATE POLICY "client_select_own_qr_token" ON public.loyalty_qr_tokens
  FOR SELECT USING (client_id = auth.uid());