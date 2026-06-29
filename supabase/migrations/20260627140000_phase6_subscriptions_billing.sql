-- ================================================================
-- PHASE 6 — Subscriptions + manual billing.
-- No payment gateway in V1 — "manual" billing means a client requests an
-- upgrade, KYNZA's team confirms a bank transfer out-of-band, then either
-- the owner or KYNZA staff marks the invoice paid (mark_invoice_paid()),
-- which flips salons.plan atomically.
-- ================================================================

CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE CHECK(key IN('free','pro','premium')),
  name TEXT NOT NULL,
  tagline TEXT NOT NULL,
  price_bif INT NOT NULL DEFAULT 0,
  period TEXT NOT NULL CHECK(period IN('lifetime','month','year')),
  features JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_featured BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.subscription_plans (key, name, tagline, price_bif, period, features, is_featured) VALUES
  ('free', 'Gratuit', 'Pour démarrer', 0, 'lifetime',
    '["20 RDV par mois","1 salon","Réservations en ligne","Fidélité clients"]'::jsonb, false),
  ('pro', 'Pro', 'Pour les salons qui grandissent', 45000, 'month',
    '["RDV illimités","Tableau de bord analytique avancé","Gestion d''équipe et commissions","Support prioritaire"]'::jsonb, true),
  ('premium', 'Premium', 'Pour les salons établis', 125000, 'year',
    '["RDV illimités","Tableau de bord analytique avancé","Gestion d''équipe et commissions","Support prioritaire","2 mois offerts vs Pro mensuel"]'::jsonb, false)
ON CONFLICT (key) DO NOTHING;

ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "subscription_plans_public_select" ON public.subscription_plans
  FOR SELECT USING (is_active = true);

CREATE TRIGGER subscription_plans_updated_at BEFORE UPDATE ON public.subscription_plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- salons.plan_started_at — when the current plan began, so billing_screen
-- can show an informational "next billing" estimate (plan_started_at +
-- 1 month/year). No automated recurring billing exists yet — purely
-- informational until a real payment gateway lands.
ALTER TABLE public.salons
  ADD COLUMN IF NOT EXISTS plan_started_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  plan_key TEXT NOT NULL REFERENCES public.subscription_plans(key),
  amount_bif INT NOT NULL,
  reference TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN('pending','paid','overdue','void')),
  payment_instructions TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  paid_at TIMESTAMPTZ,
  voided_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_invoices_salon
  ON public.invoices(salon_id) WHERE deleted_at IS NULL;

ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner_manage_invoices" ON public.invoices
  FOR ALL USING (public.has_role(auth.uid(), 'owner', salon_id))
  WITH CHECK (public.has_role(auth.uid(), 'owner', salon_id));

CREATE TRIGGER invoices_updated_at BEFORE UPDATE ON public.invoices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Atomic settle: flips the invoice to paid AND the salon's plan in one
-- statement — SECURITY INVOKER, so the caller still needs owner-level RLS
-- on both invoices (UPDATE) and salons (UPDATE) for this to do anything.
CREATE OR REPLACE FUNCTION public.mark_invoice_paid(p_invoice_id UUID)
RETURNS public.invoices
LANGUAGE plpgsql SECURITY INVOKER SET search_path = public, pg_temp AS $$
DECLARE
  v_invoice public.invoices;
BEGIN
  UPDATE public.invoices
  SET status = 'paid', paid_at = NOW()
  WHERE id = p_invoice_id AND status = 'pending' AND deleted_at IS NULL
  RETURNING * INTO v_invoice;

  IF v_invoice.id IS NULL THEN
    RAISE EXCEPTION 'invoice_not_found_or_already_settled';
  END IF;

  UPDATE public.salons
  SET plan = v_invoice.plan_key, plan_status = 'active', plan_started_at = NOW()
  WHERE id = v_invoice.salon_id;

  RETURN v_invoice;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.mark_invoice_paid(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.mark_invoice_paid(UUID) TO authenticated;