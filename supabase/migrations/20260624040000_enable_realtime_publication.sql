-- ================================================================
-- KYNZA — Migration 021 — Enable Realtime on tables the app streams.
--
-- Root cause: every Phase 2 list screen that uses Supabase Flutter's
-- `.stream()` (salonServicesProvider, salonBookingsProvider,
-- salonStaffProvider, the payment screen's transaction-status stream)
-- silently never receives live updates, because the `supabase_realtime`
-- publication starts empty on a new project — a table only broadcasts
-- Postgres Changes once explicitly added to it. Discovered while
-- verifying Phase 2 E2E: a service saved correctly to `services` (REST
-- confirmed the row) but never appeared in the Services list because
-- the StreamBuilder was listening on a publication that included none
-- of these tables.
-- ================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.services;
ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
ALTER PUBLICATION supabase_realtime ADD TABLE public.staff_profiles;
