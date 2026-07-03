-- Phase 4 (Backend Enterprise Completion) — Remote Configuration Engine
-- DRAFT — reviewed but NOT applied to the remote project, per Rule 8 of
-- docs/prompts/KYNZA_CLAUDE_CODE_PROMPT_BACKEND_ENTERPRISE_COMPLETION.md.
--
-- A versioned, auditable key/value config store. Deliberately does NOT
-- duplicate existing dedicated systems that already cover part of the
-- brief's category list: `maintenance_windows` (20260630110100),
-- `app_versions` (20260630110200), `subscription_plans` (20260627140000),
-- `feature_flags` (20260630110000 + this pass's Phase 3). Those keep their
-- own structured tables/admin screens; remote_config_entries is for looser
-- business values that don't warrant a bespoke table (prices, commissions,
-- quotas, theming tokens, onboarding copy, notification templates, workflow
-- parameters, rate limits, misc business configuration) — Phase 8 of this
-- pass widens the seeded coverage, it does not introduce a second engine.

CREATE TABLE IF NOT EXISTS public.remote_config_entries (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  key         TEXT        NOT NULL UNIQUE,
  category    TEXT        NOT NULL,
  value_json  JSONB       NOT NULL,
  value_type  TEXT        NOT NULL CHECK (value_type IN ('string', 'number', 'boolean', 'object', 'array')),
  description TEXT,
  updated_by  UUID        REFERENCES public.users(id),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at  TIMESTAMPTZ
);
ALTER TABLE public.remote_config_entries ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_remote_config_entries_category
  ON public.remote_config_entries(category) WHERE deleted_at IS NULL;

CREATE TRIGGER trg_remote_config_entries_updated_at
  BEFORE UPDATE ON public.remote_config_entries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Read = any authenticated user (config values are business parameters,
-- not tenant-scoped secrets — consistent with feature_flags' own
-- authenticated-read-all policy). Write = service_role only (via the
-- update-remote-config Edge Function's validation gate — never a direct
-- client UPDATE/INSERT/DELETE).
CREATE POLICY "remote_config_entries_authenticated_select"
  ON public.remote_config_entries FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

-- ─── Version history (append-only) ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.remote_config_versions (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_id       UUID        NOT NULL REFERENCES public.remote_config_entries(id) ON DELETE CASCADE,
  version_number INT         NOT NULL,
  value_json     JSONB       NOT NULL,
  changed_by     UUID        REFERENCES public.users(id),
  changed_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  change_reason  TEXT,
  UNIQUE (entry_id, version_number)
);
ALTER TABLE public.remote_config_versions ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_remote_config_versions_entry
  ON public.remote_config_versions(entry_id, version_number DESC);

CREATE POLICY "remote_config_versions_authenticated_select"
  ON public.remote_config_versions FOR SELECT TO authenticated USING (true);

-- ─── Audit trail (append-only) ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.remote_config_audit (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_id    UUID        NOT NULL REFERENCES public.remote_config_entries(id) ON DELETE CASCADE,
  action      TEXT        NOT NULL CHECK (action IN ('created', 'updated', 'rolled_back', 'deleted')),
  actor_id    UUID        REFERENCES public.users(id),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  before_json JSONB,
  after_json  JSONB
);
ALTER TABLE public.remote_config_audit ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_remote_config_audit_entry
  ON public.remote_config_audit(entry_id, occurred_at DESC);

CREATE POLICY "remote_config_audit_authenticated_select"
  ON public.remote_config_audit FOR SELECT TO authenticated USING (true);

-- No client-role INSERT/UPDATE/DELETE policy exists on any of the 3 tables
-- above by design — every write (including the version/audit rows) is
-- performed by the update-remote-config / rollback-remote-config Edge
-- Functions using the service_role client, which bypasses RLS entirely.
-- This is the enforcement point for "malformed value never reaches clients"
-- (Phase 4 exit criterion): validation happens before any row is written,
-- not after, and there is no other path to write these tables at all.

-- ─── Representative seed rows — one per required category ─────────────────
-- Phase 8 of this pass widens coverage; this seed only proves each category
-- from the brief is real and independently editable, not that it's
-- exhaustive yet.

INSERT INTO public.remote_config_entries (key, category, value_json, value_type, description) VALUES
  ('default_service_price_bif', 'prices', '15000', 'number', 'Prix par défaut suggéré pour un nouveau service (BIF).'),
  ('default_commission_rate_percent', 'commissions', '10', 'number', 'Taux de commission par défaut pour un nouveau membre du personnel.'),
  ('subscription_tier_pro_price_bif', 'subscription_tiers', '25000', 'number', 'Prix mensuel du plan Pro (référence — subscription_plans reste la source de vérité transactionnelle).'),
  ('max_bookings_per_day_free_tier', 'quotas', '20', 'number', 'Quota de réservations/jour pour le plan Gratuit.'),
  ('promo_banner_color_hex', 'theming', '"#D4AF37"', 'string', 'Couleur d''accent par défaut pour les bannières promotionnelles.'),
  ('onboarding_welcome_copy_key', 'onboarding_copy', '"onboarding_welcome_v1"', 'string', 'Clé de copie affichée à la première ouverture (cross-lien vers le CMS de la Phase 9, pas dupliquée ici).'),
  ('maintenance_mode_default_message_key', 'maintenance', '"evolutionMaintenanceDefaultMessage"', 'string', 'Référence à la clé i18n par défaut — maintenance_windows reste la table de vérité pour les fenêtres actives.'),
  ('booking_rate_limit_per_hour', 'rate_limits', '100', 'number', 'Reflète le paramètre déjà en dur dans check_rate_limit pour create-booking (documentation vivante, pas une seconde source de vérité tant que Phase 8 ne câble pas la lecture dynamique).'),
  ('feature_flag_default_rollout_percentage', 'feature_flag_defaults', '100', 'number', 'Valeur de rollout par défaut proposée à la création d''un nouveau flag dans l''UI admin.'),
  ('sync_retry_interval_seconds', 'sync_intervals', '30', 'number', 'Intervalle de nouvelle tentative pour MutationOutboxService.'),
  ('notification_reminder_template_key', 'notification_templates', '"booking_reminder_v1"', 'string', 'Clé de template utilisée par schedule-reminders.'),
  ('booking_cancellation_window_hours', 'workflow_parameters', '24', 'number', 'Délai minimum avant un rendez-vous pour une annulation sans pénalité.'),
  ('bank_transfer_instructions_placeholder', 'misc_business_configuration', 'true', 'boolean', 'Indicateur : les coordonnées bancaires de create-manual-invoice sont encore un placeholder — voir PRODUCTION_CHECKLIST.md.')
ON CONFLICT (key) DO NOTHING;

-- Seed version 1 for every row just inserted (idempotent: only inserts a
-- version row for entries that don't have one yet).
INSERT INTO public.remote_config_versions (entry_id, version_number, value_json, change_reason)
SELECT rce.id, 1, rce.value_json, 'initial_seed'
FROM public.remote_config_entries rce
WHERE NOT EXISTS (
  SELECT 1 FROM public.remote_config_versions rcv WHERE rcv.entry_id = rce.id
);
