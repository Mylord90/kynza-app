-- ================================================================
-- PHASE 3 — Enterprise Data Platform
-- Sub-migration 4/4: document_templates + render_template() RPC
--
-- Templates use Mustache-style {{variable}} placeholders.
-- render_template() does a simple string-replace (no logic, no loops)
-- — good enough for invoice/receipt/report one-pagers.
--
-- Types and their available variables (enforced in Flutter UI,
-- not in SQL — letting SQL validate every possible variable key
-- would make adding new variables a migration each time):
--
--   invoice:
--     {{client_name}}, {{service_name}}, {{price}},
--     {{date}}, {{salon_name}}, {{booking_id}}, {{staff_name}}
--
--   receipt:
--     all invoice vars + {{payment_method}}, {{amount_paid}}
--
--   monthly_report:
--     {{month}}, {{total_revenue}}, {{bookings_completed}},
--     {{top_service}}, {{salon_name}}, {{no_show_rate}}
--
-- is_default: at most one default per (salon_id, type).
-- Enforced via a partial unique index instead of a trigger —
-- simpler and cheaper, and the Flutter UI manages it explicitly.
-- ================================================================

CREATE TABLE IF NOT EXISTS public.document_templates (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  salon_id    UUID        NOT NULL REFERENCES public.salons(id),
  type        TEXT        NOT NULL CHECK (type IN ('invoice','receipt','monthly_report')),
  name        TEXT        NOT NULL,
  body        TEXT        NOT NULL,
  language    TEXT        NOT NULL DEFAULT 'fr',
  is_default  BOOLEAN     NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at  TIMESTAMPTZ,
  UNIQUE (salon_id, type, name)
);

-- Only one default per (salon_id, type)
CREATE UNIQUE INDEX IF NOT EXISTS idx_doc_templates_default
  ON public.document_templates (salon_id, type)
  WHERE is_default = true AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_doc_templates_salon
  ON public.document_templates (salon_id, type)
  WHERE deleted_at IS NULL;

CREATE TRIGGER document_templates_updated_at
  BEFORE UPDATE ON public.document_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE public.document_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "doc_templates_owner_manager_all" ON public.document_templates
  FOR ALL USING (
    public.has_role(auth.uid(), 'owner',   salon_id)
    OR public.has_role(auth.uid(), 'manager', salon_id)
  );

-- Staff can read templates (e.g. to preview an invoice before printing)
CREATE POLICY "doc_templates_staff_select" ON public.document_templates
  FOR SELECT USING (
    public.has_role(auth.uid(), 'staff', salon_id)
    AND deleted_at IS NULL
  );

-- ── render_template() ─────────────────────────────────────────────
-- Simple {{key}} → value substitution.  Returns NULL if template not
-- found.  SECURITY INVOKER: the caller's access to document_templates
-- is checked by RLS (above), not bypassed here.
CREATE OR REPLACE FUNCTION public.render_template(
  p_template_id UUID,
  p_variables   JSONB
)
RETURNS TEXT
LANGUAGE plpgsql SECURITY INVOKER STABLE
SET search_path = public, pg_temp
AS $$
DECLARE
  v_body  TEXT;
  v_key   TEXT;
  v_value TEXT;
BEGIN
  SELECT body INTO v_body
  FROM public.document_templates
  WHERE id = p_template_id AND deleted_at IS NULL;

  IF v_body IS NULL THEN
    RETURN NULL;
  END IF;

  FOR v_key, v_value IN
    SELECT key, value FROM jsonb_each_text(p_variables)
  LOOP
    v_body := replace(v_body, '{{' || v_key || '}}', coalesce(v_value, ''));
  END LOOP;

  RETURN v_body;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.render_template(UUID, JSONB) FROM anon;
GRANT  EXECUTE ON FUNCTION public.render_template(UUID, JSONB) TO authenticated;

-- ── Seed 3 default templates per existing salon ───────────────────
CREATE OR REPLACE FUNCTION public.create_default_document_templates(p_salon_id UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_salon_name TEXT;
BEGIN
  SELECT name INTO v_salon_name FROM public.salons WHERE id = p_salon_id;

  INSERT INTO public.document_templates (salon_id, type, name, body, is_default) VALUES
  (
    p_salon_id, 'invoice', 'Facture standard',
    '===== FACTURE =====
Salon : {{salon_name}}
Date  : {{date}}
N°    : {{booking_id}}

Client   : {{client_name}}
Prestation : {{service_name}}
Praticien  : {{staff_name}}

Montant : {{price}} FBu
========================',
    true
  ),
  (
    p_salon_id, 'receipt', 'Reçu de paiement',
    '===== REÇU =====
Salon : {{salon_name}}
Date  : {{date}}

Client          : {{client_name}}
Prestation      : {{service_name}}
Mode de paiement: {{payment_method}}

Montant payé : {{amount_paid}} FBu
Merci de votre visite !
=================',
    true
  ),
  (
    p_salon_id, 'monthly_report', 'Rapport mensuel',
    '===== RAPPORT MENSUEL =====
Salon : {{salon_name}}
Mois  : {{month}}

Réservations complétées : {{bookings_completed}}
CA total                : {{total_revenue}} FBu
Taux de no-show         : {{no_show_rate}} %
Prestation la + demandée: {{top_service}}
===========================',
    true
  )
  ON CONFLICT (salon_id, type, name) DO NOTHING;
END;
$$;

-- Trigger: auto-create templates for new salons
CREATE OR REPLACE FUNCTION public.auto_document_templates()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  PERFORM public.create_default_document_templates(NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_document_templates ON public.salons;
CREATE TRIGGER trg_auto_document_templates
  AFTER INSERT ON public.salons
  FOR EACH ROW EXECUTE FUNCTION public.auto_document_templates();

-- Backfill for salons created before this migration
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN SELECT id FROM public.salons WHERE deleted_at IS NULL LOOP
    PERFORM public.create_default_document_templates(r.id);
  END LOOP;
END;
$$;