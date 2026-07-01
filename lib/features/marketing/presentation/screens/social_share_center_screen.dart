import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/marketing/promotion_model.dart';
import '../../../../core/models/salon_full_model.dart';
import '../../../../core/models/service_model.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/services/share_service.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../../services/application/providers/service_providers.dart';
import '../../application/providers/marketing_providers.dart';

class SocialShareCenterScreen extends ConsumerWidget {
  const SocialShareCenterScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salonAsync = ref.watch(salonByIdProvider(salonId));
    final servicesAsync = ref.watch(salonServicesProvider(salonId));
    final promotionsAsync = ref.watch(promotionsProvider(salonId));
    final ownerId = ref.watch(currentUserProfileProvider).valueOrNull?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.marketingShareTitle)),
      body: salonAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: KynzaSkeleton(height: 400),
        ),
        error: (_, __) => KynzaErrorState(
          message: context.l10n.marketingLoadSalonError,
          onRetry: () => ref.invalidate(salonByIdProvider(salonId)),
        ),
        data: (salon) {
          if (salon == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              KynzaCard(
                isFeatured: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        KynzaAvatar(
                          fullName: salon.name,
                          avatarUrl: salon.logoUrl,
                          size: AvatarSize.lg,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(salon.name, style: AppTypography.h2),
                              if (salon.address != null)
                                Text(
                                  salon.address!,
                                  style: AppTypography.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    KynzaButton(
                      label: '${context.l10n.commonShare} →',
                      onPressed: () => ShareService.shareSalon(salon),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                context.l10n.marketingShareServicesTitle,
                style: AppTypography.h2,
              ),
              const SizedBox(height: AppSpacing.md),
              servicesAsync.when(
                loading: () => const KynzaSkeleton(height: 90),
                error: (_, __) => const SizedBox.shrink(),
                data: (services) {
                  if (services.isEmpty) {
                    return Text(
                      context.l10n.marketingNoServicesToShare,
                      style: AppTypography.body,
                    );
                  }
                  return SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: SizedBox(
                            width: 180,
                            child: KynzaCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.name,
                                    style: AppTypography.h3,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    service.formattedPrice,
                                    style: AppTypography.amountSm,
                                  ),
                                  const Spacer(),
                                  KynzaButton(
                                    label: context.l10n.commonShare,
                                    height: 36,
                                    onPressed: () => ShareService.shareService(
                                      salon,
                                      service,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              promotionsAsync.maybeWhen(
                data: (promos) {
                  final active = promos.where((p) => p.isLive).toList();
                  if (active.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.marketingSharePromotionTitle,
                          style: AppTypography.h2,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (final promo in active)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: KynzaCard(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          promo.title,
                                          style: AppTypography.h3,
                                        ),
                                        Text(
                                          promo.formattedDiscount,
                                          style: AppTypography.amountSm,
                                        ),
                                      ],
                                    ),
                                  ),
                                  KynzaButton(
                                    label: context.l10n.commonShare,
                                    height: 36,
                                    width: 110,
                                    onPressed: () =>
                                        ShareService.sharePromotion(
                                          salon,
                                          promo,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (ownerId != null)
                _InviteLinkCard(
                  salonId: salonId,
                  ownerId: ownerId,
                  salon: salon,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InviteLinkCard extends ConsumerWidget {
  const _InviteLinkCard({
    required this.salonId,
    required this.ownerId,
    required this.salon,
  });

  final String salonId;
  final String ownerId;
  final SalonFullModel salon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenAsync = ref.watch(
      salonReferralTokenProvider((salonId, ownerId)),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.marketingInviteLinkTitle, style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.marketingInviteLinkSubtitle,
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          tokenAsync.when(
            loading: () => const KynzaSkeleton(height: 36),
            error: (_, __) => Text(
              context.l10n.marketingInviteLinkGenError,
              style: AppTypography.bodySmall,
            ),
            data: (token) {
              final link = 'com.kynza.app://accept-referral?token=$token';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      link,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: KynzaButton(
                          label: context.l10n.marketingCopyLinkButton,
                          variant: KynzaButtonVariant.secondary,
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: link));
                            if (context.mounted) {
                              showKynzaToast(
                                context,
                                message: context.l10n.marketingLinkCopied,
                                level: ToastLevel.success,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: KynzaButton(
                          label: context.l10n.marketingShareArrowButton,
                          onPressed: () =>
                              ShareService.shareClientInvite(salon, token),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
