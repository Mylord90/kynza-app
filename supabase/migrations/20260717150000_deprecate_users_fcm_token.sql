-- KYNZA — Phase 1b, Étape 3 — deprecate users.fcm_token (comment only).
--
-- Replaced by device_tokens (multi-device, Étape 1: 20260717140000) since
-- Étape 2 Item A (a77ec8f): NotificationService.saveFcmToken() writes
-- upsert_device_token() instead, and send-notification/index.ts reads
-- device_tokens, not this column. Confirmed dead before writing this
-- comment, not assumed: grepped all of lib/ and supabase/ (functions +
-- migrations) — the only remaining references are the original
-- column-creation migration (20260623251000, historical, never rewritten)
-- and this migration's own backfill read (20260717140000, already applied,
-- one-time, not a live ongoing read). No function, view, trigger, or
-- report touches fcm_token anymore. No `fcmToken` field exists on the
-- Dart User model either — nothing transported dead-weight on every fetch.
--
-- NOT dropped. Existing values are left in place, inert. Dropping the
-- column is a future, separate ticket, once device_tokens has proven
-- stable in production over time — not decided here.
COMMENT ON COLUMN public.users.fcm_token IS
  'DEPRECATED (Phase 1b, 2026-07-17): superseded by device_tokens (multi-device). No longer written or read anywhere — see 20260717140000_device_tokens.sql. Not dropped yet; removal is a separate future ticket once the new path has proven stable.';
