-- DRAFT — reviewed but NOT applied to the remote project as part of the
-- Enterprise Architecture & Documentation Expansion pass (docs/DATABASE_ARCHITECTURE.md §4/7).
-- This repo has no local Supabase/Docker stack; `supabase db push` hits the live
-- project (hhdkjfpgaklhrhfoxlhj) directly. Apply manually after review.
--
-- Adds the 5 missing FK indexes identified by cross-referencing every
-- CREATE TABLE against its indexes across all 58 migration files.

CREATE INDEX IF NOT EXISTS idx_staff_services_salon
  ON public.staff_services (salon_id)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_staff_working_hours_salon
  ON public.staff_working_hours (salon_id)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_staff_breaks_salon
  ON public.staff_breaks (salon_id)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_automation_action_runs_salon
  ON public.automation_action_runs (salon_id);

CREATE INDEX IF NOT EXISTS idx_notification_logs_salon
  ON public.notification_logs (salon_id)
  WHERE deleted_at IS NULL AND salon_id IS NOT NULL;
