import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/router/route_names.dart';
import '../../application/providers/legal_providers.dart';

/// App-wide soft-gate banner: shown whenever the current user has at least
/// one active legal document whose current version they haven't accepted
/// yet. Non-blocking by design (Rule: soft-gate, not hard-crash) — tapping
/// it opens the first pending document; dismissing just hides it for this
/// build (it reappears next time the underlying provider refreshes).
class PolicyUpdateNotificationBanner extends ConsumerWidget {
  const PolicyUpdateNotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingPolicyUpdatesProvider);
    final pending = pendingAsync.valueOrNull ?? const [];

    if (pending.isEmpty) return const SizedBox.shrink();

    final firstPending = pending.first;

    return Material(
      color: AppColors.primaryGlow,
      child: InkWell(
        onTap: () =>
            context.push(RouteNames.legalDocumentPath(firstPending.slug)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.policyUpdateBannerMessage,
                  style: AppTypography.bodySmall,
                ),
              ),
              Text(
                context.l10n.policyUpdateBannerCta,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
