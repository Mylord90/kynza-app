import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/marketing/promotion_model.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../loyalty/application/providers/loyalty_providers.dart';
import '../../application/providers/marketing_providers.dart';
import 'invite_clients_screen.dart';
import 'loyalty_setup_screen.dart';
import 'promotion_center_screen.dart';

/// Standalone-route wrapper (deep link entry: `/owner/marketing`). The
/// owner Dashboard tab embeds [MarketingDashboardBody] directly instead,
/// since it already has its own Scaffold/AppBar shell.
class MarketingDashboardScreen extends StatelessWidget {
  const MarketingDashboardScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Marketing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => context.go(RouteNames.ownerShare),
          ),
        ],
      ),
      body: MarketingDashboardBody(salonId: salonId),
    );
  }
}

class MarketingDashboardBody extends ConsumerWidget {
  const MarketingDashboardBody({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(clientContactsProvider(salonId));
    final promotionsAsync = ref.watch(promotionsProvider(salonId));
    final programAsync = ref.watch(loyaltyProgramProvider(salonId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(clientContactsProvider(salonId));
        ref.invalidate(promotionsProvider(salonId));
        ref.invalidate(loyaltyProgramProvider(salonId));
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const KynzaOfflineBanner(),
          const SizedBox(height: AppSpacing.sm),
          _FillMyDayCard(salonId: salonId),
          const SizedBox(height: AppSpacing.xl),
          contactsAsync.when(
            loading: () => const KynzaSkeleton(height: 48),
            error: (_, __) => const SizedBox.shrink(),
            data: (contacts) => _StatsBand(contacts: contacts),
          ),
          const SizedBox(height: AppSpacing.xl),
          contactsAsync.when(
            loading: () => GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.1,
              children: const [
                KynzaSkeleton(height: 130),
                KynzaSkeleton(height: 130),
                KynzaSkeleton(height: 130),
                KynzaSkeleton(height: 130),
              ],
            ),
            error: (_, __) => KynzaErrorState(
              message: 'Impossible de charger le marketing.',
              onRetry: () => ref.invalidate(clientContactsProvider(salonId)),
            ),
            data: (contacts) {
              final unsentInvites = contacts
                  .where((c) => c.inviteSentAt == null)
                  .length;
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.1,
                children: [
                  _MarketingCard(
                    icon: Icons.person_add_outlined,
                    title: 'Mes Clients',
                    subtitle: '${contacts.length} contacts',
                    badgeLabel: contacts.isEmpty ? 'Nouveau' : '$unsentInvites',
                    badgeVariant: contacts.isEmpty
                        ? KynzaBadgeVariant.warning
                        : KynzaBadgeVariant.info,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InviteClientsScreen(salonId: salonId),
                      ),
                    ),
                  ),
                  _MarketingCard(
                    icon: Icons.share_outlined,
                    title: 'Partager mon salon',
                    subtitle: 'Touchez plus de clients',
                    badgeLabel: 'Gratuit',
                    badgeVariant: KynzaBadgeVariant.gold,
                    onTap: () => context.go(RouteNames.ownerShare),
                  ),
                  promotionsAsync.maybeWhen(
                    data: (promos) {
                      final active = promos.where((p) => p.isLive).length;
                      final expiringSoon = promos.any(
                        (p) =>
                            p.isLive &&
                            p.endsAt.difference(DateTime.now()).inDays < 2,
                      );
                      return _MarketingCard(
                        icon: Icons.local_offer_outlined,
                        title: 'Mes Promotions',
                        subtitle: '$active promotion(s) active(s)',
                        badgeLabel: expiringSoon
                            ? 'Expire bientôt'
                            : '${promos.length}',
                        badgeVariant: expiringSoon
                            ? KynzaBadgeVariant.error
                            : KynzaBadgeVariant.neutral,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PromotionCenterScreen(salonId: salonId),
                          ),
                        ),
                      );
                    },
                    orElse: () => _MarketingCard(
                      icon: Icons.local_offer_outlined,
                      title: 'Mes Promotions',
                      subtitle: '—',
                      badgeLabel: '',
                      badgeVariant: KynzaBadgeVariant.neutral,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PromotionCenterScreen(salonId: salonId),
                        ),
                      ),
                    ),
                  ),
                  programAsync.maybeWhen(
                    data: (program) => _MarketingCard(
                      icon: Icons.star_outline,
                      title: 'Fidélité',
                      subtitle:
                          '${program?.stampsRequired ?? 10} tampons = récompense',
                      badgeLabel: program == null ? 'À configurer' : 'Actif',
                      badgeVariant: program == null
                          ? KynzaBadgeVariant.warning
                          : KynzaBadgeVariant.success,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LoyaltySetupScreen(salonId: salonId),
                        ),
                      ),
                    ),
                    orElse: () => _MarketingCard(
                      icon: Icons.star_outline,
                      title: 'Fidélité',
                      subtitle: '—',
                      badgeLabel: '',
                      badgeVariant: KynzaBadgeVariant.neutral,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LoyaltySetupScreen(salonId: salonId),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text('Promotions actives', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.md),
          promotionsAsync.when(
            loading: () => const KynzaSkeleton(height: 80),
            error: (_, __) => const SizedBox.shrink(),
            data: (promos) {
              final active = promos.where((p) => p.isLive).toList();
              if (active.isEmpty) {
                return KynzaEmptyState(
                  icon: Icons.local_offer_outlined,
                  title: 'Aucune promotion',
                  subtitle: 'Créez votre première offre.',
                  ctaLabel: 'Créer une promotion +',
                  onCta: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PromotionCenterScreen(salonId: salonId),
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 96,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: active.length,
                  itemBuilder: (context, index) {
                    final promo = active[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: SizedBox(
                        width: 220,
                        child: KynzaCard(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PromotionCenterScreen(salonId: salonId),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                promo.title,
                                style: AppTypography.h3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                promo.formattedDiscount,
                                style: AppTypography.amountSm,
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
          const SizedBox(height: AppSpacing.xl),
          const Text('Contacts récents', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.md),
          contactsAsync.when(
            loading: () => const KynzaSkeleton(height: 64, count: 3),
            error: (_, __) => const SizedBox.shrink(),
            data: (contacts) {
              if (contacts.isEmpty) {
                return const Text(
                  'Aucun contact pour le moment.',
                  style: AppTypography.body,
                );
              }
              return Column(
                children: [
                  for (final contact in contacts.take(5))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: KynzaCard(
                        child: Row(
                          children: [
                            KynzaAvatar(fullName: contact.fullName),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact.fullName,
                                    style: AppTypography.h3,
                                  ),
                                  if (contact.phone != null)
                                    Text(
                                      contact.phone!,
                                      style: AppTypography.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InviteClientsScreen(salonId: salonId),
                        ),
                      ),
                      child: const Text('Voir tous mes contacts →'),
                    ),
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

class _StatsBand extends StatelessWidget {
  const _StatsBand({required this.contacts});

  final List<dynamic> contacts;

  @override
  Widget build(BuildContext context) {
    final activeClients = contacts.where((c) => c.isKynzaUser).length;
    final invitesSent = contacts.where((c) => c.inviteSentAt != null).length;
    return Row(
      children: [
        Expanded(child: _StatChip(label: '${contacts.length} contacts')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _StatChip(label: '$activeClients clients actifs')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _StatChip(label: '$invitesSent invitations')),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MarketingCard extends StatelessWidget {
  const _MarketingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeVariant,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final KynzaBadgeVariant badgeVariant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KynzaCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const Spacer(),
              if (badgeLabel.isNotEmpty)
                KynzaBadge(label: badgeLabel, variant: badgeVariant),
            ],
          ),
          const Spacer(),
          Text(title, style: AppTypography.h3),
          Text(
            subtitle,
            style: AppTypography.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Gérer →',
            style: TextStyle(color: AppColors.primary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Preserves the Phase 2 "Remplir ma journée" promo-quota share feature
/// (max 2/week via check_and_increment_promo_quota) inside the new
/// dashboard rather than dropping it.
class _FillMyDayCard extends ConsumerWidget {
  const _FillMyDayCard({required this.salonId});

  final String salonId;

  Future<void> _fillMyDay(BuildContext context) async {
    try {
      final allowed = await SupabaseService.client.rpc(
        'check_and_increment_promo_quota',
        params: {'p_salon_id': salonId},
      );
      if (allowed != true) {
        if (context.mounted) {
          showKynzaToast(
            context,
            message: 'Limite de 2 promotions par semaine atteinte.',
            level: ToastLevel.warning,
          );
        }
        return;
      }
      await Share.share(
        '🔥 Des créneaux se sont libérés aujourd\'hui ! Réservez vite via KYNZA.',
      );
    } catch (_) {
      if (context.mounted) {
        showKynzaToast(
          context,
          message: "Échec de l'envoi.",
          level: ToastLevel.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return KynzaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Remplir ma journée', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            "Des créneaux libres aujourd'hui ou demain ? Partagez une "
            'promotion à vos contacts personnels (max 2 par semaine).',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          KynzaButton(
            label: 'Partager une promo →',
            onPressed: () => _fillMyDay(context),
          ),
        ],
      ),
    );
  }
}
