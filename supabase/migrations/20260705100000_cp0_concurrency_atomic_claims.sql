-- CP0 (Enterprise Resilience & Reliability Certification) — atomic claim
-- architecture. Fixes two live-reproduced concurrency bugs from the Final
-- Enterprise Validation pass (docs/final-enterprise-validation/):
--   1. OfflineSyncCoordinator / LegalAcceptanceService double-flush — fixed
--      client-side only (lib/core/services/atomic_claim_service.dart), no
--      schema change needed for that half.
--   2. run-scheduled-actions double-processing a pending
--      automation_action_runs row when two invocations overlap (cron
--      runs every 5 min but a slow run can still overlap the next tick).
-- Also closes the same missing-atomic-claim shape found by CP0's audit in
-- schedule-reminders (TOCTOU on notification_logs, no DB backstop) and
-- OfflineSyncCoordinator's data_deletion_request branch (no unique
-- constraint backstop at all, unlike reviews.booking_id).
--
-- DRAFT ONLY — not applied to production per Rule 8. Verified live against
-- kynza-dr-scratch (see docs/enterprise-resilience/CONCURRENCY_REPORT.md).

-- 1. automation_action_runs: allow a 'processing' status so a row can be
-- atomically claimed before it's worked on, and track when it was claimed
-- so a crashed/timed-out claim can be reclaimed instead of stuck forever.
ALTER TABLE public.automation_action_runs
  DROP CONSTRAINT IF EXISTS automation_action_runs_status_check;
ALTER TABLE public.automation_action_runs
  ADD CONSTRAINT automation_action_runs_status_check
  CHECK (status IN ('pending', 'processing', 'success', 'failed', 'skipped'));
ALTER TABLE public.automation_action_runs
  ADD COLUMN IF NOT EXISTS claimed_at TIMESTAMPTZ;

-- 2. Atomic claim RPC — the `FOR UPDATE SKIP LOCKED` pattern CP0 requires.
-- Two concurrent callers racing this function can never both receive the
-- same row: Postgres row locks make the SELECT...FOR UPDATE SKIP LOCKED
-- subquery skip any row the other transaction already has locked, and the
-- UPDATE...RETURNING happens atomically in the same statement as the lock
-- acquisition — there is no read-then-later-write gap for a second caller
-- to land in. p_stale_after_minutes reclaims a row stuck in 'processing'
-- if a prior claimer crashed/timed out before finalizing it (must exceed
-- run-scheduled-actions' own execution time comfortably).
CREATE OR REPLACE FUNCTION public.claim_pending_action_runs(
  p_batch_size INT DEFAULT 50,
  p_stale_after_minutes INT DEFAULT 10,
  p_max_attempts INT DEFAULT 3
)
RETURNS SETOF public.automation_action_runs
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  UPDATE public.automation_action_runs
  SET status = 'processing', claimed_at = NOW()
  WHERE id IN (
    SELECT id FROM public.automation_action_runs
    WHERE attempt_count < p_max_attempts
      AND scheduled_at <= NOW()
      AND (
        status = 'pending'
        OR (status = 'processing' AND claimed_at < NOW() - (p_stale_after_minutes || ' minutes')::interval)
      )
    ORDER BY scheduled_at
    LIMIT p_batch_size
    FOR UPDATE SKIP LOCKED
  )
  RETURNING *;
END;
$$;

REVOKE ALL ON FUNCTION public.claim_pending_action_runs(INT, INT, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.claim_pending_action_runs(INT, INT, INT) TO service_role;

-- 3. schedule-reminders atomic claim. notification_logs itself can't carry
-- the unique constraint (send-notification legitimately writes multiple
-- rows per event — one per channel actually attempted, plus one in_app
-- row always) so a dedicated single-purpose claim table backs this
-- scheduler's own idempotency instead, same "insert wins the claim, 23505
-- means someone else already has it" idiom already used by claim-referral
-- and calculate-commission.
CREATE TABLE IF NOT EXISTS public.reminder_dispatch_claims (
  booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (booking_id, event_type)
);

ALTER TABLE public.reminder_dispatch_claims ENABLE ROW LEVEL SECURITY;
-- No policies — only service_role (schedule-reminders) ever touches this
-- table, same deny-all-by-omission pattern as data_deletion_requests'
-- missing UPDATE policy.

-- 4. data_deletion_requests: defense-in-depth backstop at the DB level.
-- The real fix for the double-insert this table was exposed to is the
-- client-side mutex (AtomicClaimService), but every other mutation this
-- offline queue backs has a DB-level backstop too (reviews.booking_id is
-- UNIQUE) and this one didn't — a second write path (e.g. a future admin
-- tool, or a bug in a future client version) could still double-insert
-- without this.
CREATE UNIQUE INDEX IF NOT EXISTS idx_data_deletion_requests_one_pending_per_user
  ON public.data_deletion_requests (user_id)
  WHERE status = 'pending' AND deleted_at IS NULL;
