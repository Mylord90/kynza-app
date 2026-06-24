-- ================================================================
-- KYNZA — Migration 022 — staff_profiles had no public SELECT policy,
-- so a Client booking a service could never see which staff exist at
-- a salon. Discovered while verifying the booking flow: "N'importe
-- quel praticien" silently returned zero slots because
-- getAvailableSlotsAnyPractitioner()'s fallback query
-- (staff_profiles WHERE salon_id=X AND is_active=true) came back
-- empty under the Client's RLS context, even though the row exists —
-- the existing policies only let owner/manager/the-staff-member-
-- themselves read this table.
--
-- Mirrors the services_public_select / salons public-discovery
-- pattern already in place. Note: invitation_token remains exposed
-- on this row to any reader (RLS is row-level, not column-level) —
-- acceptable for now since no accept-invitation flow consumes it yet,
-- but worth revisiting (a public view excluding that column) before
-- that flow ships.
-- ================================================================

CREATE POLICY "staff_profiles_public_select" ON public.staff_profiles
  FOR SELECT USING (deleted_at IS NULL AND is_active = true);
