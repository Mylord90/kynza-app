-- Supabase Advisors treatment, Checkpoint 6 — RC-8 (docs/advisors-review/).
-- 6 functions missing an explicit search_path, predating the discipline
-- established in 20260627150000_adv6_security_hardening.sql. ALTER FUNCTION
-- only (no body redefinition) — all 6 bodies confirmed to reference only
-- schema-qualified public.* objects, so this changes name resolution only,
-- not behavior (docs/advisors-review/CP5_PLAN_CORRECTION.md, Fiche 5).
--
-- Tested on kynza-dr-scratch (ref hzjmyeptytvjmzbnsmwp) per Rule 8 — NOT yet
-- applied to production (hhdkjfpgaklhrhfoxlhj), pending item-by-item approval.

ALTER FUNCTION public.check_app_version(p_platform text, p_version_code integer) SET search_path TO 'public', 'pg_temp';
ALTER FUNCTION public.check_journey_complete() SET search_path TO 'public', 'pg_temp';
ALTER FUNCTION public.evaluate_feature_flag(p_key text) SET search_path TO 'public', 'pg_temp';
ALTER FUNCTION public.init_owner_journey() SET search_path TO 'public', 'pg_temp';
ALTER FUNCTION public.is_maintenance_active() SET search_path TO 'public', 'pg_temp';
ALTER FUNCTION public.update_updated_at() SET search_path TO 'public', 'pg_temp';
