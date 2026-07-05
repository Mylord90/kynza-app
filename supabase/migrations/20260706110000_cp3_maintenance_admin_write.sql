-- Enterprise Final 100 CP3 — closes P3-11 (Master Inventory: no in-app/
-- admin UI to create a maintenance window, SQL-only today). Adds the
-- missing authenticated write path, gated to system_admin (same scope
-- every other platform-wide admin action in this codebase uses).
--
-- DRAFT ONLY — not applied to production per Rule 8. Verified live against
-- kynza-dr-scratch (Enterprise Final 100 CP3).

CREATE POLICY "maintenance_windows_admin_write" ON public.maintenance_windows
  FOR INSERT TO authenticated
  WITH CHECK (public.has_system_admin(auth.uid()));

CREATE POLICY "maintenance_windows_admin_delete" ON public.maintenance_windows
  FOR DELETE TO authenticated
  USING (public.has_system_admin(auth.uid()));

-- No UPDATE policy — a maintenance window is create/delete only (matches
-- the model's own shape: adjusting a live window is better expressed as
-- delete-and-recreate, avoiding partial-edit races on a broadcast-critical
-- record).
