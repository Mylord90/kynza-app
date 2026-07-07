-- Supabase Advisors treatment, Checkpoint 6 — RC-6c + RC-6d (docs/advisors-review/).
-- Two SECURITY DEFINER functions callable by anon/authenticated with zero internal
-- guard, confirmed live-exploitable (docs/advisors-review/CP3_CLASSIFICATION.md):
--   - check_system_alerts(): no has_system_admin() check (unlike its gated sibling
--     get_system_alerts()) -- leaks real operational metrics, triggers an
--     unauthorized write to system_alerts.
--   - claim_pending_action_runs(): no guard at all -- mutates the automation
--     queue directly. Confirmed only called by run-scheduled-actions via
--     service_role (docs/advisors-review/CP5_PLAN_CORRECTION.md, Fiches 2-3).
--
-- Both intended callers are the cron-secret-gated Edge Functions
-- (run-scheduled-actions, check-system-alerts) invoked exclusively via
-- service_role -- confirmed by direct source read of both index.ts files.
--
-- Tested on kynza-dr-scratch (ref hzjmyeptytvjmzbnsmwp) per Rule 8 — NOT yet
-- applied to production (hhdkjfpgaklhrhfoxlhj), pending item-by-item approval.

REVOKE EXECUTE ON FUNCTION public.claim_pending_action_runs(integer, integer, integer)
  FROM anon, authenticated, PUBLIC;

REVOKE EXECUTE ON FUNCTION public.check_system_alerts()
  FROM anon, authenticated, PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_system_alerts() TO service_role;
