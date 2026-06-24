import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
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
      appBar: AppBar(title: const Text('Partager mon salon')),
      body: salonAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: KynzaSkeleton(height: 400),
        ),
        error: (_, __) => KynzaErrorState(
          message: 'Impossible de charger votre salon.',
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
                      label: 'Partager →',
                      onPressed: () => ShareService.shareSalon(salon),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text('Partager mes services', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.md),
              servicesAsync.when(
                loading: () => const KynzaSkeleton(height: 90),
                error: (_, __) => const SizedBox.shrink(),
                data: (services) {
                  if (services.isEmpty) {
                    return const Text(
                      'Aucun service à partager pour le moment.',
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
                                    label: 'Partager',
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
                        const Text(
                          'Partager une promotion',
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
                                    label: 'Partager',
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
          const Text("Lien d'invitation personnalisé", style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Partagez ce lien. Vos clients téléchargent KYNZA et vous '
            'retrouvent directement.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          tokenAsync.when(
            loading: () => const KynzaSkeleton(height: 36),
            error: (_, __) => const Text(
              "Impossible de générer le lien pour l'instant.",
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
                          label: 'Copier le lien',
                          variant: KynzaButtonVariant.secondary,
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: link));
                            if (context.mounted) {
                              showKynzaToast(
                                context,
                                message: 'Lien copié !',
                                level: ToastLevel.success,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: KynzaButton(
                          label: 'Partager →',
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
