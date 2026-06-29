-- ================================================================
-- KYNZA — Enterprise Foundation V2 — Phase 1.3 — Data Versioning
--
-- The brief asks for triggers on "services + subscriptions" — there is
-- no `subscriptions` table in this codebase (checked every migration and
-- every Flutter/Edge Function call site). Subscription state actually
-- lives on `salons.plan`/`plan_status` (flipped atomically by
-- `mark_invoice_paid()`, see 20260627140000) and on `public.invoices`
-- (the actual billing/plan-change record: pending → paid → void).
-- Versioning `salons` wholesale would snapshot every unrelated edit
-- (name, address, hours, logo...) under "subscription history" — far
-- noisier than intended. `invoices` is the real analogue and is
-- low-frequency (created once, updated once by mark_invoice_paid()), so
-- triggers are applied to `services` (as literally specified) and
-- `invoices` (substituting for the non-existent `subscriptions`).
-- ================================================================

CREATE TABLE IF NOT EXISTS public.entity_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id UUID REFERENCES public.salons(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  version_number INTEGER NOT NULL,
  data JSONB NOT NULL,
  changed_fields TEXT[],
  changed_by UUID REFERENCES public.users(id),
  change_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_current BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (entity_type, entity_id, version_number)
);

CREATE INDEX IF NOT EXISTS idx_entity_versions_lookup
  ON public.entity_versions(entity_type, entity_id, version_number DESC);
CREATE INDEX IF NOT EXISTS idx_entity_versions_salon
  ON public.entity_versions(salon_id, entity_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_entity_versions_current
  ON public.entity_versions(entity_type, entity_id) WHERE is_current = TRUE;

ALTER TABLE public.entity_versions ENABLE ROW LEVEL SECURITY;
-- Matches activity_logs' owner/manager-only read access (version history
-- is exactly the kind of internal record clients/staff have no business
-- reading) — no INSERT/UPDATE/DELETE policy, only the SECURITY DEFINER
-- function below writes here.
CREATE POLICY "entity_versions_owner_manager_select" ON public.entity_versions
  FOR SELECT USING (
    public.has_role(auth.uid(), 'owner', salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

CREATE OR REPLACE FUNCTION public.create_entity_version(
  p_salon_id UUID,
  p_entity_type TEXT,
  p_entity_id UUID,
  p_data JSONB,
  p_changed_by UUID,
  p_change_reason TEXT DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  v_next_version INTEGER;
  v_changed_fields TEXT[];
  v_prev_data JSONB;
  v_new_version_id UUID;
BEGIN
  UPDATE public.entity_versions
  SET is_current = FALSE
  WHERE entity_type = p_entity_type AND entity_id = p_entity_id AND is_current = TRUE;

  SELECT COALESCE(MAX(version_number), 0) + 1 INTO v_next_version
  FROM public.entity_versions WHERE entity_type = p_entity_type AND entity_id = p_entity_id;

  SELECT data INTO v_prev_data
  FROM public.entity_versions
  WHERE entity_type = p_entity_type AND entity_id = p_entity_id
  ORDER BY version_number DESC LIMIT 1;

  IF v_prev_data IS NOT NULL THEN
    SELECT array_agg(new_data.key) INTO v_changed_fields
    FROM jsonb_each(p_data) AS new_data(key, value)
    WHERE new_data.value IS DISTINCT FROM v_prev_data->new_data.key;
  END IF;

  INSERT INTO public.entity_versions
    (salon_id, entity_type, entity_id, version_number, data, changed_fields, changed_by, change_reason, is_current)
  VALUES
    (p_salon_id, p_entity_type, p_entity_id, v_next_version, p_data, v_changed_fields, p_changed_by, p_change_reason, TRUE)
  RETURNING id INTO v_new_version_id;

  RETURN v_new_version_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_entity_version(UUID, TEXT, UUID, JSONB, UUID, TEXT)
  FROM authenticated, anon, public;

CREATE OR REPLACE FUNCTION public.trigger_create_version()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  PERFORM public.create_entity_version(
    NEW.salon_id, TG_TABLE_NAME, NEW.id, to_jsonb(NEW),
    auth.uid(), CASE WHEN TG_OP = 'INSERT' THEN 'created' ELSE 'auto_update' END
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS version_services ON public.services;
CREATE TRIGGER version_services AFTER INSERT OR UPDATE ON public.services
  FOR EACH ROW EXECUTE FUNCTION public.trigger_create_version();

DROP TRIGGER IF EXISTS version_invoices ON public.invoices;
CREATE TRIGGER version_invoices AFTER INSERT OR UPDATE ON public.invoices
  FOR EACH ROW EXECUTE FUNCTION public.trigger_create_version();