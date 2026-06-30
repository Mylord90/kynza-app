-- Phase i18n: add preferred_language column to users table
-- Stores ISO 639-1 language code (e.g. 'fr', 'en').
-- NULL means "use system default" — app falls back to auto-detection.

alter table public.users
  add column if not exists preferred_language text
    check (preferred_language in ('fr', 'en'))
    default null;

comment on column public.users.preferred_language is
  'User preferred UI language (ISO 639-1). NULL = auto-detect from device.';
