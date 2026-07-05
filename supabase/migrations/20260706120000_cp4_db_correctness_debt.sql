-- Enterprise Final 100 CP4 — closes 3 small, real, never-fixed
-- correctness/schema-debt items (Master Inventory P2-18, P3-8, P3-9),
-- each independently re-confirmed by direct inspection of the actual
-- table definitions this session, not just re-quoted.
--
-- DRAFT ONLY — not applied to production per Rule 8. Verified live against
-- kynza-dr-scratch (Enterprise Final 100 CP4).

-- ─── P2-18 — missing updated_at trigger despite the column existing ───────
-- salon_settings/permission_groups/automation_workflows all have a real
-- updated_at column but nothing ever wrote to it on UPDATE — confirmed by
-- reading each table's own migration, no CREATE TRIGGER for any of the 3
-- anywhere in the migration history. Reuses the existing update_updated_at()
-- function (20260622182007_foundation.sql), same pattern as every other
-- table that already has this trigger.

CREATE TRIGGER salon_settings_updated_at BEFORE UPDATE ON public.salon_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER permission_groups_updated_at BEFORE UPDATE ON public.permission_groups
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER automation_workflows_updated_at BEFORE UPDATE ON public.automation_workflows
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ─── P3-8 — missing deleted_at column ──────────────────────────────────────
-- Confirmed by reading each table's own CREATE TABLE statement: none of
-- the 3 has a deleted_at column at all (not "has it but unused" — genuinely
-- absent), so soft-delete is structurally impossible today for any of them.

ALTER TABLE public.salon_settings ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE public.owner_journey_progress ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE public.referrals ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- ─── P3-9 — salons.owner_id not a declared FK, no index ───────────────────
-- Confirmed: `owner_id UUID` in 20260622182007_foundation.sql, no
-- REFERENCES clause, despite being used throughout RLS (has_role() and
-- every owner-scoped policy joins through it). NOT VALID + separate
-- VALIDATE so this doesn't take a blocking full-table scan/lock on a
-- table RLS policies query constantly; today's near-zero row count makes
-- the validate step itself instant, but the pattern is correct regardless
-- of scale.

ALTER TABLE public.salons
  ADD CONSTRAINT salons_owner_id_fkey
  FOREIGN KEY (owner_id) REFERENCES public.users(id) NOT VALID;

ALTER TABLE public.salons VALIDATE CONSTRAINT salons_owner_id_fkey;

CREATE INDEX IF NOT EXISTS idx_salons_owner_id ON public.salons(owner_id);
