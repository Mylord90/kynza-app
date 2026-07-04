-- Phase 8 (Backend Enterprise Completion) — Configuration Engine coverage
-- DRAFT — reviewed but NOT applied to the remote project, per Rule 8.
--
-- Widens Phase 4's remote_config_entries seed coverage across every business
-- domain named in the brief. Introduces NO new storage mechanism — every row
-- below is a plain INSERT into the existing remote_config_entries table
-- (20260704110000_remote_config_engine.sql), confirming this phase's own
-- exit criterion ("no new config storage mechanism introduced").

INSERT INTO public.remote_config_entries (key, category, value_json, value_type, description) VALUES
  -- Working hours defaults
  ('default_working_hours_start', 'working_hours_defaults', '"08:00"', 'string', 'Heure d''ouverture par défaut proposée à la création d''un salon.'),
  ('default_working_hours_end', 'working_hours_defaults', '"18:00"', 'string', 'Heure de fermeture par défaut proposée à la création d''un salon.'),
  -- Commission rules (extends the single key seeded in Phase 4)
  ('commission_rate_type_default', 'commission_rules', '"percent"', 'string', 'Type de commission par défaut pour un nouveau membre du personnel (percent|fixed).'),
  -- Booking workflow parameters (extends Phase 4's cancellation-window key)
  ('booking_no_show_grace_period_minutes', 'booking_workflow_parameters', '15', 'number', 'Délai de grâce avant qu''une réservation soit marquée no-show.'),
  -- Loyalty rules
  ('loyalty_stamps_required_for_reward', 'loyalty_rules', '10', 'number', 'Nombre de tampons par défaut requis pour débloquer une récompense.'),
  -- Payment method availability per region
  ('payment_methods_available_bi', 'payment_method_availability', '["mobile_money","proxipay","cash"]', 'array', 'Moyens de paiement disponibles au Burundi (BI) — référence, ProxiPay reste gouverné par feature_proxipay.'),
  -- Promotion rule templates
  ('promotion_max_discount_percent', 'promotion_rule_templates', '50', 'number', 'Plafond de remise autorisé par défaut pour une promotion.'),
  -- Subscription tier definitions (extends Phase 4's pro-tier key)
  ('subscription_tier_premium_price_bif', 'subscription_tier_definitions', '45000', 'number', 'Prix mensuel du plan Premium (référence — subscription_plans reste la source de vérité transactionnelle).'),
  -- Quota thresholds (extends Phase 4's free-tier booking quota)
  ('max_staff_free_tier', 'quota_thresholds', '3', 'number', 'Nombre maximum de membres du personnel pour le plan Gratuit.'),
  -- Role/permission defaults
  ('default_permission_group_for_new_staff', 'role_permission_defaults', '"standard_staff"', 'string', 'Groupe de permissions assigné par défaut à un nouveau membre du personnel invité.')
ON CONFLICT (key) DO NOTHING;

INSERT INTO public.remote_config_versions (entry_id, version_number, value_json, change_reason)
SELECT rce.id, 1, rce.value_json, 'initial_seed'
FROM public.remote_config_entries rce
WHERE NOT EXISTS (
  SELECT 1 FROM public.remote_config_versions rcv WHERE rcv.entry_id = rce.id
);
