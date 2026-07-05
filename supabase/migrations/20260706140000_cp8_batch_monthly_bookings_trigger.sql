-- Enterprise Final 100 CP8 — closes P2-22 (Master Inventory: a per-row
-- UPDATE trigger, trg_increment_monthly_bookings, caps any single
-- bulk-insert statement around 150,000-300,000 rows before a ~2-minute
-- statement timeout — confirmed via a real 400,001-row test).
--
-- Root cause: `FOR EACH ROW` fires the function once per inserted row,
-- each doing its own `UPDATE salons` (and its own row lock acquisition on
-- the same salon row) — N executions for N rows in one statement.
--
-- Fix: a `FOR EACH STATEMENT` trigger with a transition table
-- (`REFERENCING NEW TABLE`) fires exactly once per INSERT statement,
-- regardless of row count, aggregating all affected salons' counts in one
-- UPDATE via GROUP BY. Identical net effect for the overwhelmingly common
-- single-row INSERT case (one group, one row, same +1); the difference
-- only matters for bulk inserts, which is exactly the case that had the
-- ceiling.
--
-- DRAFT ONLY — not applied to production per Rule 8. Verified live against
-- kynza-dr-scratch (Enterprise Final 100 CP8): single-row insert
-- (+1, verified correct), and a 2,000-row multi-salon bulk insert in one
-- statement (verified each salon's count increased by exactly its own
-- row count, not the other salon's, and not double-counted).

DROP TRIGGER IF EXISTS trg_increment_monthly_bookings ON public.bookings;

CREATE OR REPLACE FUNCTION public.increment_monthly_bookings_count_stmt()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  UPDATE public.salons s
  SET monthly_bookings_count = s.monthly_bookings_count + counts.cnt
  FROM (
    SELECT salon_id, COUNT(*) AS cnt
    FROM new_rows
    GROUP BY salon_id
  ) counts
  WHERE s.id = counts.salon_id;
  RETURN NULL;
END; $$;

CREATE TRIGGER trg_increment_monthly_bookings
  AFTER INSERT ON public.bookings
  REFERENCING NEW TABLE AS new_rows
  FOR EACH STATEMENT EXECUTE FUNCTION public.increment_monthly_bookings_count_stmt();

-- The old per-row function (increment_monthly_bookings_count) is left in
-- place, unreferenced by any trigger now — safe to drop in a later
-- cleanup pass once this statement-level version has run in production
-- for a while; not dropped here to keep this migration purely additive/
-- reversible with the smallest possible surface.
