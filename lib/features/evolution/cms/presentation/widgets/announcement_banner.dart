import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../../../../core/providers/app_providers.dart';
import '../../application/providers/cms_providers.dart';

/// Reusable banner consuming `cms_content` (type: announcement) — drop into
/// any home shell. Renders nothing while loading/empty/errored (an
/// announcement is optional chrome, never worth a loading flash or an error
/// state of its own).
class AnnouncementBanner extends ConsumerWidget {
  const AnnouncementBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final announcementsAsync = ref.watch(
      cmsPublishedProvider((type: 'announcement', locale: locale)),
    );

    return announcementsAsync.maybeWhen(
      data: (announcements) {
        if (announcements.isEmpty) return const SizedBox.shrink();
        final announcement = announcements.first;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.sm),
          color: AppColors.primary.withValues(alpha: 0.1),
          child: Row(
            children: [
              const Icon(Icons.campaign_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  announcement.title,
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
