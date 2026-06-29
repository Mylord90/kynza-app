-- ================================================================
-- KYNZA — Enterprise Foundation V2 — Phase 2 — Automation Platform
--
-- Trigger → Conditions → Actions, with a scheduled-action queue for
-- delay_seconds and retry-with-backoff (a single mechanism covers both:
-- "run in N seconds" and "retry in N seconds after failure" are the same
-- operation — insert/update a row with a future scheduled_at).
--
-- RLS adapted to this codebase's real convention (has_role() against
-- public.users — see Phase 1.1/1.2/1.3/1.4) rather than the brief's
-- assumed `auth.jwt()->'app_metadata'->>'salon_id'`, which nothing in
-- this schema actually uses.
-- ================================================================

-- 1. Global catalogs (not salon-scoped — KYNZA-defined, like
-- permission_definitions in Phase 1.1).
CREATE TABLE IF NOT EXISTS public.automation_trigger_types (
  id TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  description TEXT,
  available_context JSONB,
  category TEXT NOT NULL CHECK (category IN ('booking', 'staff', 'marketing', 'loyalty', 'billing'))
);

ALTER TABLE public.automation_trigger_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "automation_trigger_types_read_all" ON public.automation_trigger_types
  FOR SELECT USING (auth.role() = 'authenticated');

-- `wired` is not in the original brief — tracks whether any real code
-- path actually calls execute-workflow for this trigger yet, so the
-- builder UI can be honest about which triggers are live vs defined for
-- future use (see PHASE_2_SUMMARY.md for which is which and why).
ALTER TABLE public.automation_trigger_types ADD COLUMN IF NOT EXISTS wired BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO public.automation_trigger_types (id, label, description, available_context, category, wired) VALUES
  ('booking.created', 'Réservation créée', 'Déclenché à chaque nouvelle réservation', '{"booking_id":true,"client_id":true,"service_id":true,"staff_id":true,"amount":true}', 'booking', TRUE),
  ('booking.confirmed', 'Réservation confirmée', 'Déclenché quand le paiement Leapa confirme le RDV', '{"booking_id":true,"client_id":true}', 'booking', TRUE),
  ('booking.completed', 'Réservation terminée', 'Pas encore câblé : la transition se fait par mise à jour Flutter directe, pas par Edge Function', '{"booking_id":true,"client_id":true,"amount":true}', 'booking', FALSE),
  ('booking.cancelled', 'Réservation annulée', 'Pas encore câblé : la transition se fait par mise à jour Flutter directe, pas par Edge Function', '{"booking_id":true,"reason":true}', 'booking', FALSE),
  ('booking.no_show', 'No-show détecté', 'Déclenché par mark-no-show', '{"booking_id":true,"client_id":true}', 'booking', TRUE),
  ('review.submitted', 'Avis soumis', 'Pas encore câblé : Flutter insère directement dans reviews, aucune Edge Function/RPC à brancher', '{"review_id":true,"rating":true,"client_id":true}', 'marketing', FALSE),
  ('loyalty.card_full', 'Carte fidélité complète', 'Pas câblé depuis validate-qr (qui gère déjà ce cas directement) — évite un double envoi de la même notification. Déclenché par l''action stamp_loyalty de ce moteur.', '{"card_id":true,"client_id":true}', 'loyalty', FALSE),
  ('subscription.expiring', 'Abonnement bientôt expiré', 'Pas câblé : aucune vérification récurrente n''existe (pas de cron, pas de check-subscription)', '{"salon_id":true,"days_left":true}', 'billing', FALSE)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.automation_action_types (
  id TEXT PRIMARY KEY,
  label TEXT NOT NULL,
  description TEXT,
  required_params JSONB,
  category TEXT NOT NULL,
  implemented BOOLEAN NOT NULL DEFAULT TRUE
);

ALTER TABLE public.automation_action_types ENABLE ROW LEVEL SECURITY;
CREATE POLICY "automation_action_types_read_all" ON public.automation_action_types
  FOR SELECT USING (auth.role() = 'authenticated');

INSERT INTO public.automation_action_types (id, label, description, required_params, category, implemented) VALUES
  ('send_notification', 'Envoyer une notification', 'Réutilise send-notification existant (push+WhatsApp+in-app selon préférences utilisateur)', '{"event":true,"target":"client|owner|staff"}', 'notification', TRUE),
  ('send_whatsapp', 'Envoyer WhatsApp', 'Alias de send_notification — l''infrastructure existante envoie déjà sur WhatsApp automatiquement selon les préférences utilisateur, pas besoin d''un chemin séparé', '{"event":true,"target":"client|owner|staff"}', 'notification', TRUE),
  ('stamp_loyalty', 'Tamponner carte fidélité', 'Ajoute 1 tampon via add_loyalty_stamp() ; déclenche loyalty.card_full si la carte devient pleine', '{}', 'loyalty', TRUE),
  ('add_loyalty_bonus', 'Ajouter bonus fidélité', 'Ajoute N tampons bonus via add_loyalty_bonus_stamps()', '{"stamps":true,"reason":false}', 'loyalty', TRUE),
  ('log_activity', 'Journaliser l''activité', 'Écrit directement dans activity_logs', '{"action":true,"severity":false}', 'audit', TRUE),
  ('update_stats', 'Mettre à jour les statistiques', 'Non implémenté — aucune cible concrète (mv_daily_revenue n''existe pas encore, Phase 3)', '{}', 'analytics', FALSE),
  ('send_email', 'Envoyer un email', 'Non implémenté — R14 interdit l''email pour une alerte opérationnelle, et aucune infra email n''existe dans ce projet', '{"template":true,"to":true}', 'notification', FALSE),
  ('create_invoice', 'Créer une facture', 'Non implémenté — invoices.plan_key référence subscription_plans, incompatible avec un montant/description libre tel que décrit ici', '{"amount":true,"description":true}', 'billing', FALSE)
ON CONFLICT (id) DO NOTHING;

-- 2. Workflows (per salon).
CREATE TABLE IF NOT EXISTS public.automation_workflows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  trigger_type TEXT NOT NULL REFERENCES public.automation_trigger_types(id),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  is_system BOOLEAN NOT NULL DEFAULT FALSE,
  priority INTEGER NOT NULL DEFAULT 0,
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  execution_count INTEGER NOT NULL DEFAULT 0,
  last_executed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_automation_workflows_salon_active
  ON public.automation_workflows(salon_id, is_active) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_automation_workflows_trigger
  ON public.automation_workflows(trigger_type) WHERE is_active = TRUE AND deleted_at IS NULL;

ALTER TABLE public.automation_workflows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "automation_workflows_select" ON public.automation_workflows
  FOR SELECT USING (
    public.has_role(auth.uid(), 'owner', salon_id) OR public.has_role(auth.uid(), 'manager', salon_id)
  );
CREATE POLICY "automation_workflows_insert" ON public.automation_workflows
  FOR INSERT WITH CHECK (
    public.has_role(auth.uid(), 'owner', salon_id) OR public.has_role(auth.uid(), 'manager', salon_id)
  );
-- "templates KYNZA — non modifiables" enforced at the DB layer, not just
-- hidden in the UI: is_system rows can never be UPDATEd/DELETEd by
-- anyone but service_role (which bypasses RLS entirely).
CREATE POLICY "automation_workflows_update" ON public.automation_workflows
  FOR UPDATE USING (
    is_system = FALSE
    AND (public.has_role(auth.uid(), 'owner', salon_id) OR public.has_role(auth.uid(), 'manager', salon_id))
  );
CREATE POLICY "automation_workflows_delete" ON public.automation_workflows
  FOR DELETE USING (
    is_system = FALSE
    AND (public.has_role(auth.uid(), 'owner', salon_id) OR public.has_role(auth.uid(), 'manager', salon_id))
  );

-- 3. Conditions (per workflow). Same is_system protection, via a join —
-- without it, someone could still rewrite a system template's behavior
-- through its child rows even though the workflow row itself is locked.
CREATE TABLE IF NOT EXISTS public.automation_conditions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id UUID NOT NULL REFERENCES public.automation_workflows(id) ON DELETE CASCADE,
  field TEXT NOT NULL,
  operator TEXT NOT NULL CHECK (operator IN ('eq', 'neq', 'gt', 'lt', 'gte', 'lte', 'in', 'contains')),
  value JSONB NOT NULL,
  logical_operator TEXT NOT NULL DEFAULT 'AND' CHECK (logical_operator IN ('AND', 'OR')),
  order_index INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_automation_conditions_workflow
  ON public.automation_conditions(workflow_id, order_index);

ALTER TABLE public.automation_conditions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "automation_conditions_select" ON public.automation_conditions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.automation_workflows w WHERE w.id = workflow_id
      AND (public.has_role(auth.uid(), 'owner', w.salon_id) OR public.has_role(auth.uid(), 'manager', w.salon_id))
    )
  );
CREATE POLICY "automation_conditions_insert" ON public.automation_conditions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.automation_workflows w WHERE w.id = workflow_id AND w.is_system = FALSE
      AND (public.has_role(auth.uid(), 'owner', w.salon_id) OR public.has_role(auth.uid(), 'manager', w.salon_id))
    )
  );
CREATE POLICY "automation_conditions_update" ON public.automation_conditions
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.automation_workflows w WHERE w.id = workflow_id AND w.is_system = FALSE
      AND (public.has_role(auth.uid(), 'owner', w.salon_id) OR public.has_role(auth.uid(), 'manager', w.salon_id))
    )
  );
CREATE POLICY "automation_conditions_delete" ON public.automation_conditions
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.automation_workflows w WHERE w.id = workflow_id AND w.is_system = FALSE
      AND (public.has_role(auth.uid(), 'owner', w.salon_id) OR public.has_role(auth.uid(), 'manager', w.salon_id))
    )
  );

-- 4. Actions (per workflow, ordered). Same protection pattern as conditions.
CREATE TABLE IF NOT EXISTS public.automation_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id UUID NOT NULL REFERENCES public.automation_workflows(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL REFERENCES public.automation_action_types(id),
  params JSONB NOT NULL DEFAULT '{}',
  delay_seconds INTEGER NOT NULL DEFAULT 0,
  order_index INTEGER NOT NULL DEFAULT 0,
  is_async BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_automation_actions_workflow
  ON public.automation_actions(workflow_id, order_index);

ALTER TABLE public.automation_actions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "automation_actions_select" ON public.automation_actions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.automation_workflows w WHERE w.id = workflow_id
      AND (public.has_role(auth.uid(), 'owner', w.salon_id) OR public.has_role(auth.uid(), 'manager', w.salon_id))
    )
  );
CREATE POLICY "automation_actions_insert" ON public.automation_actions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.automation_workflows w WHERE w.id = workflow_id AND w.is_system = FALSE
      AND (public.has_role(auth.uid(), 'owner', w.salon_id) OR public.has_role(auth.uid(), 'manager', w.salon_id))
    )
  );
CREATE POLICY "automation_actions_update" ON public.automation_actions
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.automation_workflows w WHERE w.id = workflow_id AND w.is_system = FALSE
      AND (public.has_role(auth.uid(), 'owner', w.salon_id) OR public.has_role(auth.uid(), 'manager', w.salon_id))
    )
  );
CREATE POLICY "automation_actions_delete" ON public.automation_actions
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.automation_workflows w WHERE w.id = workflow_id AND w.is_system = FALSE
      AND (public.has_role(auth.uid(), 'owner', w.salon_id) OR public.has_role(auth.uid(), 'manager', w.salon_id))
    )
  );

-- 5. Execution logs — one row per workflow firing.
CREATE TABLE IF NOT EXISTS public.automation_execution_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_id UUID NOT NULL REFERENCES public.automation_workflows(id) ON DELETE CASCADE,
  salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
  trigger_type TEXT NOT NULL,
  trigger_context JSONB,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'success', 'failed', 'skipped')),
  error_message TEXT,
  actions_executed INTEGER NOT NULL DEFAULT 0,
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  duration_ms INTEGER
);

CREATE INDEX IF NOT EXISTS idx_automation_exec_logs_workflow
  ON public.automation_execution_logs(workflow_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_automation_exec_logs_salon
  ON public.automation_execution_logs(salon_id, started_at DESC);

ALTER TABLE public.automation_execution_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "automation_exec_logs_select" ON public.automation_execution_logs
  FOR SELECT USING (
    public.has_role(auth.uid(), 'owner', salon_id) OR public.has_role(auth.uid(), 'manager', salon_id)
  );
-- No client-facing INSERT/UPDATE/DELETE policy — only the Edge Functions
-- (service_role) write execution logs.

-- 6. Scheduled action queue — backs BOTH delay_seconds (initial
-- scheduled_at = NOW() + delay) and retry-with-backoff (reschedule on
-- failure) through the same mechanism: a row due to run at a future time.
CREATE TABLE IF NOT EXISTS public.automation_action_runs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  execution_log_id UUID NOT NULL REFERENCES public.automation_execution_logs(id) ON DELETE CASCADE,
  action_id UUID NOT NULL REFERENCES public.automation_actions(id) ON DELETE CASCADE,
  salon_id UUID NOT NULL REFERENCES public.salons(id) ON DELETE CASCADE,
  context JSONB NOT NULL DEFAULT '{}',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'success', 'failed', 'skipped')),
  attempt_count INTEGER NOT NULL DEFAULT 0,
  scheduled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_error TEXT,
  executed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Plain (non-partial) index — a predicate on NOW() is rejected by
-- Postgres for the same reason found in Phase 1.1's permission cache
-- index (functions in an index predicate must be IMMUTABLE).
CREATE INDEX IF NOT EXISTS idx_automation_action_runs_due
  ON public.automation_action_runs(status, scheduled_at);
CREATE INDEX IF NOT EXISTS idx_automation_action_runs_execution
  ON public.automation_action_runs(execution_log_id);

ALTER TABLE public.automation_action_runs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "automation_action_runs_select" ON public.automation_action_runs
  FOR SELECT USING (
    public.has_role(auth.uid(), 'owner', salon_id) OR public.has_role(auth.uid(), 'manager', salon_id)
  );

-- 7. add_loyalty_bonus_stamps() — mirrors add_loyalty_stamp()'s atomic
-- pattern for an arbitrary stamp count. loyalty_stamp_logs.action is
-- CHECK'd to ('earned','redeemed','expired') — 'bonus' is not a valid
-- value, so this logs as 'earned' with a descriptive note instead of
-- widening that constraint for one new caller.
CREATE OR REPLACE FUNCTION public.add_loyalty_bonus_stamps(
  p_card_id UUID, p_stamps INT, p_reason TEXT DEFAULT NULL
) RETURNS public.loyalty_cards
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  v_card public.loyalty_cards;
BEGIN
  UPDATE public.loyalty_cards
  SET stamps_count = stamps_count + p_stamps,
      total_stamps_earned = total_stamps_earned + p_stamps,
      last_stamp_at = NOW()
  WHERE id = p_card_id AND deleted_at IS NULL
  RETURNING * INTO v_card;

  IF v_card.id IS NULL THEN
    RAISE EXCEPTION 'loyalty_card_not_found';
  END IF;

  INSERT INTO public.loyalty_stamp_logs (card_id, salon_id, client_id, action, stamps_delta, note)
  VALUES (v_card.id, v_card.salon_id, v_card.client_id, 'earned', p_stamps, COALESCE('Bonus: ' || p_reason, 'Bonus fidélité'));

  RETURN v_card;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.add_loyalty_bonus_stamps(UUID, INT, TEXT) FROM authenticated, anon, public;
GRANT EXECUTE ON FUNCTION public.add_loyalty_bonus_stamps(UUID, INT, TEXT) TO service_role;