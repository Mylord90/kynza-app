-- Supabase Advisors treatment, Checkpoint 6 — RC-4 (docs/advisors-review/).
-- 15 foreign keys without a covering index, on tables from subsystems deployed
-- after P2-15's original 32-index batch (CMS, Remote Config, Feature Flags,
-- Legal Center, Audit). Same low-risk pattern as P2-15 — plain CREATE INDEX,
-- tables currently near-empty. Column names confirmed against
-- information_schema.key_column_usage in production before drafting this file
-- (docs/advisors-review/CP5_PLAN_CORRECTION.md, Fiche 4).
--
-- Tested on kynza-dr-scratch (ref hzjmyeptytvjmzbnsmwp) per Rule 8 — NOT yet
-- applied to production (hhdkjfpgaklhrhfoxlhj), pending item-by-item approval.

CREATE INDEX IF NOT EXISTS idx_cms_content_versions_changed_by ON public.cms_content_versions (changed_by);
CREATE INDEX IF NOT EXISTS idx_experiment_assignments_user_id ON public.experiment_assignments (user_id);
CREATE INDEX IF NOT EXISTS idx_experiment_events_user_id ON public.experiment_events (user_id);
CREATE INDEX IF NOT EXISTS idx_legal_documents_current_version ON public.legal_documents (current_version_id);
CREATE INDEX IF NOT EXISTS idx_remote_config_audit_actor_id ON public.remote_config_audit (actor_id);
CREATE INDEX IF NOT EXISTS idx_remote_config_entries_updated_by ON public.remote_config_entries (updated_by);
CREATE INDEX IF NOT EXISTS idx_remote_config_versions_changed_by ON public.remote_config_versions (changed_by);
CREATE INDEX IF NOT EXISTS idx_role_feature_overrides_flag_key ON public.role_feature_overrides (flag_key);
CREATE INDEX IF NOT EXISTS idx_services_source_template_id ON public.services (source_template_id);
CREATE INDEX IF NOT EXISTS idx_system_admin_audit_actor_id ON public.system_admin_audit (actor_id);
CREATE INDEX IF NOT EXISTS idx_user_feature_overrides_flag_key ON public.user_feature_overrides (flag_key);
CREATE INDEX IF NOT EXISTS idx_user_feature_overrides_user_id ON public.user_feature_overrides (user_id);
CREATE INDEX IF NOT EXISTS idx_user_legal_acceptances_doc_version_id ON public.user_legal_acceptances (document_version_id);
CREATE INDEX IF NOT EXISTS idx_user_permission_groups_user_id ON public.user_permission_groups (user_id);
CREATE INDEX IF NOT EXISTS idx_user_permission_overrides_user_id ON public.user_permission_overrides (user_id);
