-- ================================================================
-- KYNZA — Migration 017 — Guest users for Owner-created walk-in bookings
-- (Owner Dashboard "+ Nouveau RDV" FAB — client has no KYNZA account).
-- ================================================================

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_guest BOOLEAN NOT NULL DEFAULT false;

-- Guest accounts have no password and never log in themselves — only the
-- create-walkin-booking Edge Function (service_role) ever creates or
-- updates them, so no new client-facing RLS policy is needed here.
