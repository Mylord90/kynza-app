-- ================================================================
-- KYNZA — Migration 016 — Staff ranking (R11: position only, amounts
-- of colleagues must never reach the client — bookings RLS already
-- prevents a Staff session from reading other practitioners' rows
-- directly, so the rank itself must be computed server-side).
-- ================================================================

CREATE OR REPLACE FUNCTION public.get_staff_week_rank(p_staff_id UUID)
RETURNS TABLE(rank BIGINT, team_size BIGINT)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  v_salon_id UUID;
  v_week_start TIMESTAMPTZ := date_trunc('week', NOW());
BEGIN
  SELECT salon_id INTO v_salon_id FROM public.staff_profiles WHERE id = p_staff_id;

  IF v_salon_id IS NULL OR NOT (
    public.has_role(auth.uid(), 'staff', v_salon_id)
    AND EXISTS (SELECT 1 FROM public.staff_profiles WHERE id = p_staff_id AND user_id = auth.uid())
  ) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  RETURN QUERY
  WITH revenue AS (
    SELECT b.practitioner_id, SUM(b.amount_bif) AS total
    FROM public.bookings b
    WHERE b.salon_id = v_salon_id
      AND b.status = 'completed'
      AND b.start_time >= v_week_start
      AND b.deleted_at IS NULL
    GROUP BY b.practitioner_id
  ),
  ranked AS (
    SELECT practitioner_id, RANK() OVER (ORDER BY total DESC) AS rnk
    FROM revenue
  )
  SELECT
    COALESCE((SELECT rnk FROM ranked WHERE practitioner_id = p_staff_id), 0),
    (SELECT COUNT(*) FROM public.staff_profiles WHERE salon_id = v_salon_id AND deleted_at IS NULL);
END; $$;

GRANT EXECUTE ON FUNCTION public.get_staff_week_rank(UUID) TO authenticated;
