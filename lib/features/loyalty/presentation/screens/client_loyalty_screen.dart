import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/loyalty_providers.dart';
import '../widgets/loyalty_card_widget.dart';

class ClientLoyaltyScreen extends ConsumerWidget {
  const ClientLoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(clientLoyaltyCardsProvider);

    return cardsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 2,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: KynzaSkeleton(height: 220),
        ),
      ),
      error: (_, __) => KynzaErrorState(
        message: 'Impossible de charger vos cartes de fidélité.',
        onRetry: () => ref.invalidate(clientLoyaltyCardsProvider),
      ),
      data: (cards) {
        final active = cards.where((c) => c.deletedAt == null).toList();
        if (active.isEmpty) {
          return KynzaEmptyState(
            icon: Icons.star_outline,
            title: 'Aucune carte de fidélité',
            subtitle:
                'Réservez votre premier RDV pour commencer à collecter des '
                'tampons ! 💛',
            ctaLabel: 'Découvrir les salons',
            onCta: () => context.go(RouteNames.homeClient),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: active.length,
          itemBuilder: (context, index) =>
              LoyaltyCardWidget(card: active[index]),
        );
      },
    );
  }
}
