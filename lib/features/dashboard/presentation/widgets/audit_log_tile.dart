import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/audit_log_model.dart';
import '../../../../l10n/app_localizations.dart';

IconData _iconFor(String typeAction) {
  if (typeAction.startsWith('booking_')) return Icons.calendar_today_outlined;
  if (typeAction.startsWith('payment_') || typeAction.startsWith('refund_')) {
    return Icons.payments_outlined;
  }
  if (typeAction.startsWith('staff_')) return Icons.people_outline;
  if (typeAction.startsWith('permission_')) return Icons.shield_outlined;
  return Icons.settings_outlined;
}

Color _severityColor(String severity) => switch (severity) {
  'critical' || 'error' => AppColors.error,
  'warning' => AppColors.warning,
  _ => AppColors.textMuted,
};

String _eventLabel(AppLocalizations l10n, String event) => switch (event) {
  'user_login' => l10n.auditEventUserLogin,
  'user_logout' => l10n.auditEventUserLogout,
  'profile_updated' => l10n.auditEventProfileUpdated,
  'role_changed' => l10n.auditEventRoleChanged,
  'salon_updated' => l10n.auditEventSalonUpdated,
  'salon_status_changed' => l10n.auditEventSalonStatusChanged,
  'staff_invited' => l10n.auditEventStaffInvited,
  'staff_invitation_accepted' => l10n.auditEventStaffInvitationAccepted,
  'staff_removed' => l10n.auditEventStaffRemoved,
  'staff_joined' => l10n.auditEventStaffJoined,
  'booking_created' => l10n.auditEventBookingCreated,
  'booking_confirmed' => l10n.auditEventBookingConfirmed,
  'booking_cancelled' => l10n.auditEventBookingCancelled,
  'booking_completed' => l10n.auditEventBookingCompleted,
  'booking_no_show' => l10n.auditEventBookingNoShow,
  'payment_completed' => l10n.auditEventPaymentCompleted,
  'payment_failed' => l10n.auditEventPaymentFailed,
  'refund_initiated' => l10n.auditEventRefundInitiated,
  'discount_applied' => l10n.auditEventDiscountApplied,
  'loyalty_stamp_added' => l10n.auditEventLoyaltyStampAdded,
  'loyalty_reward_redeemed' => l10n.auditEventLoyaltyRewardRedeemed,
  'referral_claimed' => l10n.auditEventReferralClaimed,
  'permission_group_created' => l10n.auditEventPermissionGroupCreated,
  'permission_group_deleted' => l10n.auditEventPermissionGroupDeleted,
  'permission_group_permission_changed' =>
    l10n.auditEventPermissionGroupPermissionChanged,
  'permission_group_member_added' => l10n.auditEventPermissionGroupMemberAdded,
  'permission_group_member_removed' =>
    l10n.auditEventPermissionGroupMemberRemoved,
  _ => event,
};

class AuditLogTile extends StatelessWidget {
  const AuditLogTile({super.key, required this.log});

  final AuditLogModel log;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md_,
        border: Border.all(
          color: log.severity == 'info'
              ? AppColors.border
              : _severityColor(log.severity).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _iconFor(log.typeAction),
            color: _severityColor(log.severity) == AppColors.textMuted
                ? AppColors.primary
                : _severityColor(log.severity),
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _eventLabel(context.l10n, log.typeAction),
                        style: AppTypography.body,
                      ),
                    ),
                    if (log.isSensitive)
                      const Padding(
                        padding: EdgeInsets.only(left: AppSpacing.xs),
                        child: Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                if (log.userName != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(log.userName!, style: AppTypography.bodySmall),
                ],
              ],
            ),
          ),
          if (log.createdAt != null)
            Text(
              '${log.createdAt!.day}/${log.createdAt!.month} '
              '${log.createdAt!.hour.toString().padLeft(2, '0')}:'
              '${log.createdAt!.minute.toString().padLeft(2, '0')}',
              style: AppTypography.bodySmall,
            ),
        ],
      ),
    );
  }
}
