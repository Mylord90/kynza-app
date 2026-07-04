-- DRAFT — reviewed but NOT applied to the remote project (hhdkjfpgaklhrhfoxlhj), per Rule 8.
-- KYNZA Enterprise Final Certification Pass, CP2 (Phase 8 — Database Optimization).
--
-- Source: `supabase db advisors --linked --type performance` (real command output against the
-- live project, docs/certification/PHASE_2_DATABASE_OPTIMIZATION.md), NOT speculation. This is
-- the `unindexed_foreign_keys` finding minus the 5 already covered by the pre-existing draft
-- `20260703120000_indexes_optimization.sql` (staff_services/staff_working_hours/staff_breaks/
-- automation_action_runs.salon_id/notification_logs.salon_id) — 27 net-new FK columns across 20
-- tables, zero overlap (checked by constraint name against that file before writing this one).
--
-- No `WHERE deleted_at IS NULL` partial predicate is added here (unlike the pre-existing draft)
-- because confirming `deleted_at` presence per table individually was out of proportion for this
-- checkpoint — whoever applies this can add a partial predicate per table if desired; a full
-- index is always correct, just marginally larger.

CREATE INDEX IF NOT EXISTS idx_automation_action_runs_action ON public.automation_action_runs (action_id);
CREATE INDEX IF NOT EXISTS idx_automation_actions_action_type ON public.automation_actions (action_type);
CREATE INDEX IF NOT EXISTS idx_automation_workflows_created_by ON public.automation_workflows (created_by);
CREATE INDEX IF NOT EXISTS idx_availability_exceptions_staff ON public.availability_exceptions (staff_id);
CREATE INDEX IF NOT EXISTS idx_availability_overrides_staff ON public.availability_overrides (staff_id);
CREATE INDEX IF NOT EXISTS idx_backup_jobs_initiated_by ON public.backup_jobs (initiated_by);
CREATE INDEX IF NOT EXISTS idx_entity_versions_changed_by ON public.entity_versions (changed_by);
CREATE INDEX IF NOT EXISTS idx_invoices_plan_key ON public.invoices (plan_key);
CREATE INDEX IF NOT EXISTS idx_loyalty_qr_tokens_used_by ON public.loyalty_qr_tokens (used_by);
CREATE INDEX IF NOT EXISTS idx_loyalty_stamp_logs_booking ON public.loyalty_stamp_logs (booking_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_windows_created_by ON public.maintenance_windows (created_by);
CREATE INDEX IF NOT EXISTS idx_notification_logs_related_booking ON public.notification_logs (related_booking_id);
CREATE INDEX IF NOT EXISTS idx_owner_journey_progress_owner ON public.owner_journey_progress (owner_id);
CREATE INDEX IF NOT EXISTS idx_permission_group_permissions_permission ON public.permission_group_permissions (permission_id);
CREATE INDEX IF NOT EXISTS idx_proxipay_sessions_staff ON public.proxipay_sessions (staff_id);
CREATE INDEX IF NOT EXISTS idx_proxipay_sessions_client ON public.proxipay_sessions (client_id);
CREATE INDEX IF NOT EXISTS idx_reviews_client ON public.reviews (client_id);
CREATE INDEX IF NOT EXISTS idx_salon_feature_overrides_flag_key ON public.salon_feature_overrides (flag_key);
CREATE INDEX IF NOT EXISTS idx_search_logs_user ON public.search_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_staff_profiles_invited_by ON public.staff_profiles (invited_by);
CREATE INDEX IF NOT EXISTS idx_user_effective_permissions_cache_user ON public.user_effective_permissions_cache (user_id);
CREATE INDEX IF NOT EXISTS idx_user_permission_groups_user ON public.user_permission_groups (user_id);
CREATE INDEX IF NOT EXISTS idx_user_permission_groups_group ON public.user_permission_groups (group_id);
CREATE INDEX IF NOT EXISTS idx_user_permission_groups_granted_by ON public.user_permission_groups (granted_by);
CREATE INDEX IF NOT EXISTS idx_user_permission_overrides_granted_by ON public.user_permission_overrides (granted_by);
CREATE INDEX IF NOT EXISTS idx_user_permission_overrides_permission ON public.user_permission_overrides (permission_id);
CREATE INDEX IF NOT EXISTS idx_user_permission_overrides_user ON public.user_permission_overrides (user_id);
