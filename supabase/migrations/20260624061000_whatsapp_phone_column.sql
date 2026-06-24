-- ================================================================
-- KYNZA — Migration 018 — Phase 2.2 / Module 1 — WhatsApp opt-in
-- Additive only. Separate from users.phone (used for OTP/auth) since a
-- client may want WhatsApp alerts on a different number, and must opt
-- in explicitly before any WhatsApp send is attempted (R14).
-- ================================================================

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS whatsapp_phone TEXT,
  ADD COLUMN IF NOT EXISTS whatsapp_opt_in BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS whatsapp_opt_in_at TIMESTAMPTZ;
