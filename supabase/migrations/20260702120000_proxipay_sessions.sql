-- ═══════════════════════════════════════════════════
-- ProxiPay V1 — QR-based in-person payment session pairing
-- proxipay_sessions is a pairing/handoff layer only: it never stores a
-- Mobile Money number and never moves money itself. The actual charge is
-- a normal `transactions` row created by proxipay-confirm (service_role),
-- reusing the same idempotency-key/Leapa/leapa-webhook path create-payment
-- already uses. Written/updated exclusively by Edge Functions
-- (proxipay-create-session, proxipay-confirm) — R16.
-- ═══════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.proxipay_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.bookings(id),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  staff_id UUID NOT NULL REFERENCES public.users(id),
  client_id UUID REFERENCES public.users(id),
  amount_bif INT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'confirmed', 'expired', 'cancelled')),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '3 minutes'),
  confirmed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_proxipay_sessions_booking
  ON public.proxipay_sessions(booking_id);
CREATE INDEX IF NOT EXISTS idx_proxipay_sessions_salon
  ON public.proxipay_sessions(salon_id, created_at DESC);

ALTER TABLE public.proxipay_sessions ENABLE ROW LEVEL SECURITY;

-- Staff/manager/owner of the salon can watch sessions they created.
CREATE POLICY "proxipay_sessions_salon_staff_select" ON public.proxipay_sessions
  FOR SELECT USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
    OR public.has_role(auth.uid(), 'staff', salon_id)
  );

-- Any authenticated client can resolve a still-pending, unexpired session
-- by id (needed to show amount/salon after scanning) — no sensitive data
-- is ever stored on this row, so this is safe to leave broad.
CREATE POLICY "proxipay_sessions_pending_select" ON public.proxipay_sessions
  FOR SELECT USING (status = 'pending' AND expires_at > NOW());

-- No INSERT/UPDATE policy for `authenticated` — both mutating paths go
-- through proxipay-create-session / proxipay-confirm using the
-- service_role client, which bypasses RLS entirely.

ALTER PUBLICATION supabase_realtime ADD TABLE public.proxipay_sessions;

COMMENT ON TABLE public.proxipay_sessions IS
  'ProxiPay pairing sessions (QR handoff between staff and an in-person '
  'client). Money movement lives in transactions, not here — see '
  'proxipay-create-session / proxipay-confirm Edge Functions.';
