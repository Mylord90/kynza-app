-- referrals.referral_token needs a server-side default so the app can
-- lazily create a salon-wide "generic invite" row without generating a
-- UUID client-side (every other UUID PK/token in this schema gets one).
ALTER TABLE public.referrals
  ALTER COLUMN referral_token SET DEFAULT gen_random_uuid();

-- Owner Success Journey milestone push, dispatched the same way as
-- loyalty_reward_available — best-effort via send-notification.
INSERT INTO public.notification_templates (event_type, title_fr, body_fr, channels) VALUES
  ('journey_step_complete', 'Bravo, encore un peu ! 🚀',
   'Votre configuration KYNZA est à {{pct}}% — plus que quelques étapes avant de recevoir vos premiers RDV.',
   ARRAY['push'])
ON CONFLICT (event_type) DO NOTHING;