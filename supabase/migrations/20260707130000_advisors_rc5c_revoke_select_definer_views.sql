-- Supabase Advisors treatment, Checkpoint 6 — RC-5c (docs/advisors-review/).
-- 29 SECURITY DEFINER views + 2 materialized views readable directly by
-- anon/authenticated, bypassing the has_system_admin()-gated RPC wrapper each
-- one was built behind. Confirmed live-exploitable in production
-- (docs/advisors-review/CP3_CLASSIFICATION.md): unauthenticated GET returned
-- real rows for v_audit_security_trail (2), v_audit_fraud_proxipay (1),
-- mv_audit_stats (6), mv_daily_revenue (2), and reachable-but-empty for the
-- rest (near-zero traffic today, not a mitigation).
--
-- Excluded deliberately (already judged intentional/safe, CP3):
-- v_popular_searches, v_mv_daily_revenue (the wrapper view, not the raw MV),
-- v_staff_directory_public.
--
-- Every RPC wrapper (get_bi_*, get_audit_*, get_*_dashboard) is itself
-- SECURITY DEFINER and owned by postgres, so it keeps working after this
-- REVOKE -- it never depended on the caller's own grant on the underlying
-- view. Confirmed by exhaustive repo-wide grep (docs/advisors-review/
-- CP5_PLAN_CORRECTION.md, Fiche 1): zero call sites outside
-- supabase/migrations/ reference any of these 31 objects directly.
--
-- REVOKE ALL, not just SELECT: pg_class.relacl confirmed (Checkpoint 2 +
-- re-confirmed on dr-scratch before writing this migration) that anon and
-- authenticated hold the full default grant (arwdDxtm -- every privilege,
-- not only SELECT) on all 31 objects. A SELECT-only REVOKE would have left
-- INSERT/UPDATE/DELETE/TRUNCATE/REFERENCES/TRIGGER in place.
--
-- Tested on kynza-dr-scratch (ref hzjmyeptytvjmzbnsmwp) per Rule 8 — NOT yet
-- applied to production (hhdkjfpgaklhrhfoxlhj), pending item-by-item approval.

REVOKE ALL PRIVILEGES ON TABLE
  public.v_audit_automation_execution, public.v_audit_commission_accuracy,
  public.v_audit_financial_accounting, public.v_audit_fraud_proxipay, public.v_audit_rgpd_trail,
  public.v_audit_salon_performance, public.v_audit_security_trail, public.v_audit_user_behavior,
  public.v_bi_activation, public.v_bi_bookings, public.v_bi_clients, public.v_bi_commissions,
  public.v_bi_conversion, public.v_bi_loyalty, public.v_bi_ltv, public.v_bi_payments,
  public.v_bi_referrals, public.v_bi_revenue, public.v_bi_salons, public.v_bi_staff,
  public.v_bi_subscriptions, public.v_crash_dashboard, public.v_edge_function_dashboard,
  public.v_notification_dashboard, public.v_payment_dashboard, public.v_queue_dashboard,
  public.v_security_dashboard, public.v_storage_dashboard, public.v_supabase_dashboard,
  public.mv_audit_stats, public.mv_daily_revenue
FROM anon, authenticated, PUBLIC;
