-- DRAFT — reviewed but NOT applied to any project, per Rule 8. Bundles two small, independent
-- hardening fixes from the KYNZA Final Enterprise Verification pass (CP2, CP11), each narrow
-- enough not to warrant its own migration file.
--
-- FIX 1 (CP2, docs/certification-v2/CP2_DEEP_SECURITY.md): create_default_document_templates
-- had zero caller-identity/role check and was confirmed live-exploitable by a fully
-- unauthenticated caller against kynza-dr-scratch (any anon request could seed default document
-- templates for an arbitrary existing salon_id). Same defensive pattern already used correctly by
-- check_and_increment_promo_quota — require the caller to be owner/manager of that salon.
CREATE OR REPLACE FUNCTION public.create_default_document_templates(p_salon_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_salon_name TEXT;
BEGIN
  IF NOT (
    public.has_role(auth.uid(), 'owner', p_salon_id)
    OR public.has_role(auth.uid(), 'manager', p_salon_id)
  ) THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

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
$function$;

-- NOTE: auto_document_templates() (the trigger fired on new-salon creation) calls this function
-- via PERFORM as the same SECURITY DEFINER context that inserted the salon row — since a brand
-- new salon's owner is also the one whose auth.uid() fired the INSERT that triggered this, the
-- has_role() check above still passes for the legitimate trigger-driven path. Confirmed by
-- reading auto_document_templates()'s definition (CP2) — it does not call this function with any
-- different caller context.

-- FIX 2 (CP2, cosmetic hardening): get_staff_week_rank's own internal check already makes it safe
-- for anon (auth.uid() is NULL for anon, so its forbidden-check always raises) — but the EXECUTE
-- grant to anon is dead weight that invites exactly the kind of "why does this SECURITY DEFINER
-- function accept anon calls" question CP2 had to spend time answering. Tightening the grant
-- costs nothing and removes the question for the next reviewer.
--
-- UPDATE (Remediation v1, Phase 2) — the original `REVOKE ... FROM anon` above was tested live on
-- kynza-dr-scratch and found to be a no-op: `has_function_privilege('anon', 'get_staff_week_rank
-- (uuid)', 'execute')` still returned true after applying it. Root cause: `pg_proc.proacl` showed
-- `{=X/postgres,...}` — the bare `=X` entry is PostgreSQL's implicit grant to the PUBLIC
-- pseudo-role (present by default on every function unless explicitly revoked at creation), and
-- every role, including `anon`, inherits PUBLIC's privileges regardless of any role-specific
-- REVOKE. Revoking from `anon` specifically only removes an anon-specific grant that never
-- existed here; the real access was coming from PUBLIC. Fixed by revoking from PUBLIC instead —
-- re-verified live after this change: `has_function_privilege('anon', ...)` now correctly returns
-- false, while `authenticated`/`service_role`'s separate explicit grants (already present in
-- `proacl`) are untouched, so legitimate authenticated callers are unaffected.
REVOKE EXECUTE ON FUNCTION public.get_staff_week_rank(uuid) FROM PUBLIC;
