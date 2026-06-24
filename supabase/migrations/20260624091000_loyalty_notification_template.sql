-- Loyalty reward-available push, dispatched via the existing
-- send-notification Edge Function (event_type-driven template lookup).
INSERT INTO public.notification_templates (event_type, title_fr, body_fr, channels) VALUES
  ('loyalty_reward_available', 'Récompense disponible ! 🎉',
   'Vous avez complété votre carte de fidélité chez {{salon_name}}. {{reward}}',
   ARRAY['push'])
ON CONFLICT (event_type) DO NOTHING;