-- ================================================================
-- KYNZA — Phase 1.4 follow-up.
--
-- json_serializable's snake_case codegen for notifReminderHoursBefore2
-- produces notif_reminder_hours_before2 (no underscore before a trailing
-- digit), not the original column name notif_reminder_hours_before_2.
-- The previous fix used @JsonKey to override the codegen name, but
-- Freezed's generated output for @JsonKey on a constructor parameter
-- unconditionally emits 3 "ignore: invalid_annotation_target" comments
-- that the analyzer then flags as unnecessary (duplicate_ignore) — an
-- unavoidable side effect of that annotation with this Freezed version,
-- not fixable from the consuming side. Renaming the column to match
-- the codegen's natural output removes the need for @JsonKey entirely.
-- ================================================================

ALTER TABLE public.salon_settings
  RENAME COLUMN notif_reminder_hours_before_2 TO notif_reminder_hours_before2;