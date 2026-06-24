import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/notification_log_model.dart';

/// Leading icon color per event family — gold=booking created/reminder,
/// green=confirmed, red=cancelled/no-show, blue=staff/system.
Color _iconColorFor(String eventType) {
  if (eventType.contains('confirmed')) return AppColors.success;
  if (eventType.contains('cancelled') || eventType.contains('no_show')) {
    return AppColors.error;
  }
  if (eventType.startsWith('staff_')) return AppColors.info;
  return AppColors.primary;
}

IconData _iconFor(String eventType) {
  if (eventType.contains('confirmed')) return Icons.check_circle_outline;
  if (eventType.contains('cancelled')) return Icons.cancel_outlined;
  if (eventType.contains('reminder')) return Icons.alarm_outlined;
  if (eventType.startsWith('staff_')) return Icons.people_outline;
  return Icons.calendar_today_outlined;
}

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  if (diff.inHours < 24) return '${diff.inHours} h';
  if (diff.inDays < 7) return '${diff.inDays} j';
  return '${time.day}/${time.month}/${time.year}';
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationLogModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = notification.isUnread;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.md_,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isUnread ? AppColors.surfaceVariant : AppColors.surface,
          borderRadius: AppRadius.md_,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _iconFor(notification.eventType),
              color: _iconColorFor(notification.eventType),
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: isUnread
                        ? AppTypography.h3
                        : AppTypography.h3.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.body,
                    style: AppTypography.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _timeAgo(notification.createdAt ?? DateTime.now()),
                  style: AppTypography.bodySmall,
                ),
                if (isUnread) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
