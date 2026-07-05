-- Enterprise Final 100 CP7 — closes P2-11 (Master Inventory: no unique
-- constraint on proxipay_sessions.booking_id — "the single most-repeated
-- never-fixed finding in this entire program," flagged independently by
-- 5 separate passes, never actually drafted by any of them).
--
-- A compromised/buggy staff session could otherwise create multiple
-- concurrent ProxiPay payment sessions for the same booking, bounded only
-- by the existing 30 req/60s rate limit, not an explicit guard.
--
-- Partial unique index (only 'pending' sessions conflict) rather than a
-- table-wide UNIQUE: a booking legitimately gets a new session after a
-- prior one expired/was cancelled — those aren't a race, only two
-- simultaneously-pending sessions for the same booking are.
--
-- DRAFT ONLY — not applied to production per Rule 8. Verified live against
-- kynza-dr-scratch (Enterprise Final 100 CP7).

CREATE UNIQUE INDEX IF NOT EXISTS idx_proxipay_sessions_one_pending_per_booking
  ON public.proxipay_sessions (booking_id)
  WHERE status = 'pending';
