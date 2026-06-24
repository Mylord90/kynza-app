-- ================================================================
-- KYNZA — Migration 015 — Keep salons.monthly_bookings_count current
-- (backs the freemium enforcement in FreemiumService / create-booking).
-- ================================================================

CREATE OR REPLACE FUNCTION public.increment_monthly_bookings_count()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  UPDATE public.salons
  SET monthly_bookings_count = monthly_bookings_count + 1
  WHERE id = NEW.salon_id;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_increment_monthly_bookings ON public.bookings;
CREATE TRIGGER trg_increment_monthly_bookings
  AFTER INSERT ON public.bookings
  FOR EACH ROW EXECUTE FUNCTION public.increment_monthly_bookings_count();

-- Reset every salon's counter at the start of each month.
SELECT cron.schedule(
  'reset-monthly-bookings-count',
  '0 0 1 * *',
  $$ UPDATE public.salons SET monthly_bookings_count = 0; $$
);
