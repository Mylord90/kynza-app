-- Phase 7 (Backend Enterprise Completion) — A/B Testing Engine
-- TRACK B — engine only, no live experiments in this pass. DRAFT — reviewed
-- but NOT applied to the remote project, per Rule 8.

CREATE TABLE IF NOT EXISTS public.experiments (
  id                 UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  key                TEXT        NOT NULL UNIQUE,
  name               TEXT        NOT NULL,
  hypothesis         TEXT,
  status             TEXT        NOT NULL DEFAULT 'draft'
                                  CHECK (status IN ('draft', 'running', 'paused', 'concluded')),
  variant_config_json JSONB      NOT NULL DEFAULT '{"control":50,"treatment":50}'::jsonb,
  started_at         TIMESTAMPTZ,
  ended_at           TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at         TIMESTAMPTZ
);
ALTER TABLE public.experiments ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER trg_experiments_updated_at
  BEFORE UPDATE ON public.experiments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Authenticated read of experiment config (needed client-side to compute a
-- deterministic assignment without a round trip per-event) — write is
-- SYSTEM_ADMIN only, this is platform-wide experiment definition, not a
-- salon-tenant concern.
CREATE POLICY "experiments_authenticated_select"
  ON public.experiments FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

CREATE POLICY "experiments_admin_all"
  ON public.experiments FOR ALL TO authenticated
  USING (public.has_system_admin(auth.uid()))
  WITH CHECK (public.has_system_admin(auth.uid()));

CREATE TABLE IF NOT EXISTS public.experiment_assignments (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  experiment_id UUID        NOT NULL REFERENCES public.experiments(id) ON DELETE CASCADE,
  user_id       UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  variant       TEXT        NOT NULL,
  assigned_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (experiment_id, user_id)
);
ALTER TABLE public.experiment_assignments ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_experiment_assignments_experiment
  ON public.experiment_assignments (experiment_id);

-- A user may record/read only their own assignment — the assignment itself
-- is computed deterministically client-side (offline-capable, no round
-- trip needed to know the variant); this row exists so server-side
-- reporting can later cross-reference which variant a user landed in
-- without recomputing it, and so a user's assignment survives a reinstall.
CREATE POLICY "experiment_assignments_self"
  ON public.experiment_assignments FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE TABLE IF NOT EXISTS public.experiment_events (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  experiment_id UUID        NOT NULL REFERENCES public.experiments(id) ON DELETE CASCADE,
  user_id       UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  event_key     TEXT        NOT NULL,
  occurred_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.experiment_events ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_experiment_events_experiment
  ON public.experiment_events (experiment_id, event_key);

CREATE POLICY "experiment_events_self_insert"
  ON public.experiment_events FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "experiment_events_admin_select"
  ON public.experiment_events FOR SELECT TO authenticated
  USING (public.has_system_admin(auth.uid()));

-- No experiment is seeded as 'running' — the engine is ready, but zero
-- experiments are actually live at the end of this phase, by design (exit
-- criterion). One 'draft' example proves the schema end-to-end without
-- going live.
INSERT INTO public.experiments (key, name, hypothesis, status, variant_config_json) VALUES
  ('onboarding_cta_copy', 'Onboarding CTA copy test',
   'A more direct CTA copy increases first-booking completion.', 'draft',
   '{"control":50,"treatment":50}')
ON CONFLICT (key) DO NOTHING;
