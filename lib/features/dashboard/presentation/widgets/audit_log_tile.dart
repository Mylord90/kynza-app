import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/audit_log_model.dart';

IconData _iconFor(String typeAction) {
  if (typeAction.startsWith('booking_')) return Icons.calendar_today_outlined;
  if (typeAction.startsWith('payment_') || typeAction.startsWith('refund_')) {
    return Icons.payments_outlined;
  }
  if (typeAction.startsWith('staff_')) return Icons.people_outline;
  return Icons.settings_outlined;
}

String _descriptionFor(AuditLogModel log) {
  const labels = {
    'user_login': 'Connexion',
    'user_logout': 'Déconnexion',
    'profile_updated': 'Profil mis à jour',
    'role_changed': 'Rôle modifié',
    'salon_updated': 'Salon mis à jour',
    'salon_status_changed': 'Statut du salon modifié',
    'staff_invited': 'Invitation envoyée',
    'staff_invitation_accepted': "Invitation acceptée",
    'staff_removed': 'Membre retiré',
    'staff_joined': "Nouveau membre dans l'équipe",
    'booking_created': 'Réservation créée',
    'booking_confirmed': 'Réservation confirmée',
    'booking_cancelled': 'Réservation annulée',
    'booking_completed': 'Réservation terminée',
    'booking_no_show': 'Client absent (no-show)',
    'payment_completed': 'Paiement réussi',
    'payment_failed': 'Paiement échoué',
    'refund_initiated': 'Remboursement initié',
    'discount_applied': 'Réduction appliquée',
    'loyalty_stamp_added': 'Tampon fidélité ajouté',
    'loyalty_reward_redeemed': 'Récompense fidélité validée',
    'referral_claimed': 'Parrainage utilisé',
  };
  return labels[log.typeAction] ?? log.typeAction;
}

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
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_iconFor(log.typeAction), color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_descriptionFor(log), style: AppTypography.body),
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
