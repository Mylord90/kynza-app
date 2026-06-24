-- ================================================================
-- KYNZA — Migration 012 — fcm_token column (needed by send-notification,
-- pulled forward from Subphase H since G's leapa-webhook already calls it)
-- ================================================================

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
