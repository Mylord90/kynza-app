-- ================================================================
-- KYNZA — Migration 010 — Phase 2 / Subphase E — Booking engine
-- ================================================================

CREATE TABLE IF NOT EXISTS public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id),
  client_id UUID NOT NULL REFERENCES public.users(id),
  practitioner_id UUID NOT NULL REFERENCES public.staff_profiles(id),
  service_id UUID NOT NULL REFERENCES public.services(id),
  status TEXT NOT NULL CHECK(status IN(
    'pending_payment','confirmed','in_progress',
    'completed','cancelled','no_show'
  )) DEFAULT 'pending_payment',
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  buffer_end_time TIMESTAMPTZ NOT NULL,
  amount_bif INT NOT NULL CHECK(amount_bif >= 0),
  payment_status TEXT NOT NULL CHECK(payment_status IN(
    'pending','processing','completed','failed','reversed','expired'
  )) DEFAULT 'pending',
  payment_method TEXT,
  idempotency_key VARCHAR(255) UNIQUE,
  deposit_required BOOLEAN NOT NULL DEFAULT false,
  deposit_amount_bif INT NOT NULL DEFAULT 0,
  notes TEXT,
  cancellation_reason TEXT,
  cancelled_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  no_show_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  CONSTRAINT uq_practitioner_slot UNIQUE(practitioner_id, start_time)
);

CREATE INDEX IF NOT EXISTS idx_bookings_salon_date
  ON public.bookings(salon_id, start_time)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_bookings_practitioner
  ON public.bookings(practitioner_id, start_time)
  WHERE deleted_at IS NULL AND status NOT IN('cancelled','no_show');
CREATE INDEX IF NOT EXISTS idx_bookings_client
  ON public.bookings(client_id, start_time DESC)
  WHERE deleted_at IS NULL;

ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- Owner/Manager: all bookings in their salon
CREATE POLICY "owner_manager_bookings" ON public.bookings
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

-- Staff: own bookings only (read + status updates, never other columns)
CREATE POLICY "staff_own_bookings_select" ON public.bookings
  FOR SELECT USING (
    practitioner_id IN (
      SELECT id FROM public.staff_profiles WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "staff_own_bookings_update" ON public.bookings
  FOR UPDATE USING (
    practitioner_id IN (
      SELECT id FROM public.staff_profiles WHERE user_id = auth.uid()
    )
  );

-- Client: own bookings
CREATE POLICY "client_own_bookings_select" ON public.bookings
  FOR SELECT USING (client_id = auth.uid());

-- Booking creation goes through the create-booking Edge Function
-- (service_role) so the practitioner-slot lock is atomic — no direct
-- client INSERT policy exists on purpose (see kynza-booking-engine.md §2).

CREATE TRIGGER bookings_updated_at BEFORE UPDATE ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- A staff member with future bookings can no longer be hard-removed —
-- mirrors kynza-booking-engine.md §11. staff_profiles soft-delete (the
-- app's removeStaff()) is blocked at the trigger level too, since RLS
-- alone cannot express "no future bookings exist" at UPDATE time.
CREATE OR REPLACE FUNCTION public.prevent_staff_removal_with_future_bookings()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    IF EXISTS (
      SELECT 1 FROM public.bookings
      WHERE practitioner_id = OLD.id
        AND start_time > NOW()
        AND deleted_at IS NULL
        AND status NOT IN ('cancelled', 'no_show')
    ) THEN
      RAISE EXCEPTION 'Impossible de retirer ce membre : RDV futurs existants.';
    END IF;
  END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_prevent_staff_removal ON public.staff_profiles;
CREATE TRIGGER trg_prevent_staff_removal
  BEFORE UPDATE ON public.staff_profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_staff_removal_with_future_bookings();

-- Releases pending_payment bookings that have sat unpaid for 5+ minutes
-- (slot lock window, kynza-booking-engine.md §3). pg_cron must be enabled
-- on the project for this to actually run on a schedule.
CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule(
  'release-expired-bookings',
  '* * * * *',
  $$
    UPDATE public.bookings
    SET status = 'cancelled', cancellation_reason = 'payment_timeout'
    WHERE status = 'pending_payment'
      AND created_at < NOW() - INTERVAL '5 minutes'
      AND deleted_at IS NULL;
  $$
);
