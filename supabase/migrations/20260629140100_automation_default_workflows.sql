-- ================================================================
-- KYNZA — Enterprise Foundation V2 — Phase 2 follow-up.
--
-- Auto-creates the 4 KYNZA template workflows for every salon, mirroring
-- the salon_settings pattern from Phase 1.4: a trigger for future salons
-- + an explicit backfill for salons that already exist (the trigger
-- alone never covers pre-existing rows — this was easy to miss the
-- first time, in 1.4, so doing it from the start here).
--
-- Two new notification_templates rows are needed
-- ('booking_no_show_owner_alert', 'review_request') — 'booking_confirmed'
-- and 'loyalty_reward_available' already exist and are reused as-is.
-- ================================================================

INSERT INTO public.notification_templates (event_type, title_fr, body_fr, channels) VALUES
  ('booking_no_show_owner_alert', 'Client absent ⚠️',
   '{{client_name}} ne s''est pas présenté(e) à son RDV.',
   ARRAY['push']),
  ('review_request', 'Comment était votre visite ? ⭐',
   'Donnez votre avis sur votre RDV chez {{salon_name}} et aidez ce salon à s''améliorer.',
   ARRAY['push', 'whatsapp'])
ON CONFLICT (event_type) DO NOTHING;

CREATE OR REPLACE FUNCTION public.create_default_automation_workflows(p_salon_id UUID, p_owner_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
DECLARE
  v_workflow_id UUID;
BEGIN
  IF EXISTS (SELECT 1 FROM public.automation_workflows WHERE salon_id = p_salon_id AND is_system = TRUE) THEN
    RETURN;
  END IF;

  INSERT INTO public.automation_workflows (salon_id, name, description, trigger_type, is_system, created_by)
  VALUES (p_salon_id, 'RDV confirmé → Notification client',
    'Notifie le client dès que son RDV est confirmé.', 'booking.confirmed', TRUE, p_owner_id)
  RETURNING id INTO v_workflow_id;
  INSERT INTO public.automation_actions (workflow_id, action_type, params, delay_seconds, order_index)
  VALUES (v_workflow_id, 'send_notification', '{"event":"booking_confirmed","target":"client"}'::jsonb, 0, 0);

  INSERT INTO public.automation_workflows (salon_id, name, description, trigger_type, is_system, created_by)
  VALUES (p_salon_id, 'RDV terminé → Fidélité + Demande d''avis',
    'Tamponne la carte de fidélité puis demande un avis 2h après le RDV.', 'booking.completed', TRUE, p_owner_id)
  RETURNING id INTO v_workflow_id;
  INSERT INTO public.automation_actions (workflow_id, action_type, params, delay_seconds, order_index) VALUES
    (v_workflow_id, 'stamp_loyalty', '{}'::jsonb, 0, 0),
    (v_workflow_id, 'send_notification', '{"event":"review_request","target":"client"}'::jsonb, 7200, 1);

  INSERT INTO public.automation_workflows (salon_id, name, description, trigger_type, is_system, created_by)
  VALUES (p_salon_id, 'No-show → Alerte propriétaire',
    'Alerte le propriétaire dès qu''un client est marqué absent.', 'booking.no_show', TRUE, p_owner_id)
  RETURNING id INTO v_workflow_id;
  INSERT INTO public.automation_actions (workflow_id, action_type, params, delay_seconds, order_index)
  VALUES (v_workflow_id, 'send_notification', '{"event":"booking_no_show_owner_alert","target":"owner"}'::jsonb, 0, 0);

  INSERT INTO public.automation_workflows (salon_id, name, description, trigger_type, is_system, created_by)
  VALUES (p_salon_id, 'Carte fidélité pleine → Notification client',
    'Notifie le client quand sa carte de fidélité est complète.', 'loyalty.card_full', TRUE, p_owner_id)
  RETURNING id INTO v_workflow_id;
  INSERT INTO public.automation_actions (workflow_id, action_type, params, delay_seconds, order_index)
  VALUES (v_workflow_id, 'send_notification', '{"event":"loyalty_reward_available","target":"client"}'::jsonb, 0, 0);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_default_automation_workflows(UUID, UUID) FROM authenticated, anon, public;

CREATE OR REPLACE FUNCTION public.trigger_create_default_automation_workflows()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp AS $$
BEGIN
  PERFORM public.create_default_automation_workflows(NEW.id, NEW.owner_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS auto_default_automation_workflows ON public.salons;
CREATE TRIGGER auto_default_automation_workflows AFTER INSERT ON public.salons
  FOR EACH ROW EXECUTE FUNCTION public.trigger_create_default_automation_workflows();

DO $$
DECLARE
  v_salon RECORD;
BEGIN
  FOR v_salon IN SELECT id, owner_id FROM public.salons LOOP
    PERFORM public.create_default_automation_workflows(v_salon.id, v_salon.owner_id);
  END LOOP;
END;
$$;