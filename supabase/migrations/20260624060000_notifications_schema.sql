-- ================================================================
-- KYNZA — Migration 017 — Phase 2.2 / Module 1 — Notifications system
-- notification_templates (static, seeded) + notification_logs (one row
-- per send attempt/channel) + notification_preferences (per-user opt-in).
-- ================================================================

-- 1. notification_templates — static event_type → message definitions
CREATE TABLE IF NOT EXISTS public.notification_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type TEXT NOT NULL UNIQUE,
  title_fr TEXT NOT NULL,
  body_fr TEXT NOT NULL,
  channels TEXT[] NOT NULL DEFAULT ARRAY['push'],
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

INSERT INTO public.notification_templates (event_type, title_fr, body_fr, channels) VALUES
  ('booking_created', 'Nouvelle réservation ✅',
   'RDV créé chez {{salon_name}} le {{date}} à {{time}} pour {{service_name}}.',
   ARRAY['push','whatsapp']),
  ('booking_confirmed', 'RDV confirmé ✅',
   'Votre RDV chez {{salon_name}} est confirmé pour le {{date}} à {{time}}.',
   ARRAY['push','whatsapp']),
  ('booking_cancelled', 'RDV annulé',
   'Votre RDV du {{date}} à {{time}} chez {{salon_name}} a été annulé.',
   ARRAY['push','whatsapp']),
  ('booking_reminder_24h', 'Rappel RDV demain ⏰',
   'N''oubliez pas votre RDV demain à {{time}} chez {{salon_name}}.',
   ARRAY['push','whatsapp']),
  ('booking_reminder_2h', 'RDV dans 2 heures ⏰',
   'Votre RDV chez {{salon_name}} est dans 2 heures à {{time}}.',
   ARRAY['push']),
  ('staff_invited', 'Invitation équipe KYNZA',
   '{{owner_name}} vous invite à rejoindre {{salon_name}} sur KYNZA.',
   ARRAY['push','whatsapp']),
  ('staff_joined', 'Nouveau membre 🎉',
   '{{staff_name}} a rejoint votre équipe sur KYNZA.',
   ARRAY['push']),
  ('service_created', 'Service ajouté',
   'Le service "{{service_name}}" a été ajouté à votre catalogue.',
   ARRAY['push'])
ON CONFLICT (event_type) DO NOTHING;

ALTER TABLE public.notification_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notif_templates_public_select" ON public.notification_templates
  FOR SELECT USING (is_active = true AND deleted_at IS NULL);

CREATE TRIGGER notif_templates_updated_at BEFORE UPDATE ON public.notification_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 2. notification_logs — one row per send attempt (push/whatsapp/in_app)
CREATE TABLE IF NOT EXISTS public.notification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id),
  salon_id UUID REFERENCES public.salons(id),
  event_type TEXT NOT NULL,
  channel TEXT NOT NULL CHECK(channel IN('push','whatsapp','in_app')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB NOT NULL DEFAULT '{}',
  is_read BOOLEAN NOT NULL DEFAULT false,
  read_at TIMESTAMPTZ,
  delivered BOOLEAN NOT NULL DEFAULT false,
  delivery_error TEXT,
  related_booking_id UUID REFERENCES public.bookings(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_notif_logs_user
  ON public.notification_logs(user_id, created_at DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_notif_logs_user_unread
  ON public.notification_logs(user_id, created_at DESC)
  WHERE deleted_at IS NULL AND is_read = false;

ALTER TABLE public.notification_logs ENABLE ROW LEVEL SECURITY;

-- Own notifications: full read/write (mark read, soft delete) for the
-- recipient only — no client INSERT policy on purpose, every row is
-- written by send-notification under service_role (bypasses RLS).
CREATE POLICY "notif_logs_own_select" ON public.notification_logs
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "notif_logs_own_update" ON public.notification_logs
  FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Owner/manager can audit every notification sent within their salon.
CREATE POLICY "notif_logs_owner_manager_select" ON public.notification_logs
  FOR SELECT USING (
    salon_id IS NOT NULL
    AND (
      public.has_role(auth.uid(), 'owner', salon_id)
      OR public.has_role(auth.uid(), 'manager', salon_id)
    )
  );

CREATE TRIGGER notif_logs_updated_at BEFORE UPDATE ON public.notification_logs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 3. notification_preferences — one row per user, upserted on first visit
-- to the settings screen; absence of a row means "all defaults enabled".
CREATE TABLE IF NOT EXISTS public.notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.users(id),
  push_enabled BOOLEAN NOT NULL DEFAULT true,
  whatsapp_enabled BOOLEAN NOT NULL DEFAULT true,
  email_enabled BOOLEAN NOT NULL DEFAULT false,
  booking_created BOOLEAN NOT NULL DEFAULT true,
  booking_confirmed BOOLEAN NOT NULL DEFAULT true,
  booking_cancelled BOOLEAN NOT NULL DEFAULT true,
  booking_reminder_24h BOOLEAN NOT NULL DEFAULT true,
  booking_reminder_2h BOOLEAN NOT NULL DEFAULT true,
  staff_events BOOLEAN NOT NULL DEFAULT true,
  marketing BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notif_prefs_own" ON public.notification_preferences
  FOR ALL USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE TRIGGER notif_prefs_updated_at BEFORE UPDATE ON public.notification_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
