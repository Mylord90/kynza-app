-- ================================================================
-- KYNZA — Migration 011 — Phase 2 / Subphase G — Leapa transactions
-- ================================================================

CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  booking_id UUID NOT NULL REFERENCES public.bookings(id),
  leapa_reference TEXT UNIQUE,
  leapa_transaction_id TEXT,
  amount_bif INT NOT NULL CHECK(amount_bif > 0),
  method TEXT NOT NULL CHECK(method IN('lumicash','ecocash','enoti','cash')),
  status TEXT NOT NULL CHECK(status IN(
    'pending','processing','completed','failed','reversed','expired'
  )) DEFAULT 'pending',
  idempotency_key VARCHAR(255) UNIQUE NOT NULL,
  error_code TEXT,
  error_message TEXT,
  initiated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  confirmed_at TIMESTAMPTZ,
  reversed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_transactions_booking
  ON public.transactions(booking_id);
CREATE INDEX IF NOT EXISTS idx_transactions_salon
  ON public.transactions(salon_id, created_at DESC)
  WHERE deleted_at IS NULL;

ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Owner only (R07 — financial isolation). No INSERT/UPDATE policy for the
-- client roles: every write goes through a service_role Edge Function.
CREATE POLICY "owner_view_transactions" ON public.transactions
  FOR SELECT USING (public.has_role(auth.uid(), 'owner', salon_id));

CREATE POLICY "client_own_transactions" ON public.transactions
  FOR SELECT USING (
    booking_id IN (SELECT id FROM public.bookings WHERE client_id = auth.uid())
  );

CREATE TRIGGER transactions_updated_at BEFORE UPDATE ON public.transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
