-- Master Plan Execution CP2 — closes P2-24 (Master Inventory:
-- `docs/KYNZA_FINAL_PRODUCTION_DEPLOYMENT_MASTER_PLAN.md`). `notification_logs`
-- was never added to the `supabase_realtime` publication when it was created
-- (20260624060000_notifications_schema.sql) or when the publication itself was
-- populated (20260624040000_enable_realtime_publication.sql) — new
-- notifications don't appear live on an already-open screen, only on next
-- initial-snapshot load. Same root cause/fix shape as
-- 20260624040000_enable_realtime_publication.sql.
--
-- DRAFT ONLY — not applied to production per Rule 8. Verified live against
-- kynza-dr-scratch (Master Plan Execution CP2).

ALTER PUBLICATION supabase_realtime ADD TABLE public.notification_logs;
