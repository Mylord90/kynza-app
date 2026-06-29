-- ================================================================
-- KYNZA — Enterprise Foundation V2 — Phase 1.4 follow-up.
--
-- Phase 1.2's audit migration deferred settings-change logging because
-- salon_settings didn't exist yet. It exists now (this phase) — add
-- 'settings_changed' to logs_self_insert_safe's type_action whitelist so
-- AuditLogger.settingsChanged() (wired into salon_settings_providers.dart)
-- can actually write a row instead of silently failing the RLS check.
-- ================================================================

DROP POLICY IF EXISTS "logs_self_insert_safe" ON public.activity_logs;
CREATE POLICY "logs_self_insert_safe" ON public.activity_logs
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    AND salon_id IN (SELECT salon_id FROM public.users WHERE id = auth.uid())
    AND type_action IN (
      'user_login', 'user_logout', 'profile_updated', 'role_changed',
      'salon_updated', 'salon_status_changed',
      'staff_invited', 'staff_removed', 'staff_invitation_accepted',
      'booking_created', 'booking_confirmed', 'booking_cancelled',
      'booking_completed', 'booking_no_show',
      'payment_completed', 'payment_failed', 'refund_initiated',
      'discount_applied', 'referral_claimed',
      'loyalty_stamp_added', 'loyalty_reward_redeemed',
      'permission_group_created', 'permission_group_deleted',
      'permission_group_permission_changed',
      'permission_group_member_added', 'permission_group_member_removed',
      'settings_changed'
    )
  );