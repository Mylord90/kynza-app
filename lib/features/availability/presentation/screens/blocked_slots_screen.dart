import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/availability_providers.dart';

class BlockedSlotsScreen extends ConsumerWidget {
  const BlockedSlotsScreen({super.key, required this.salonId});

  final String salonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overridesAsync = ref.watch(salonOverridesProvider(salonId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Jours bloqués')),
      body: overridesAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: KynzaSkeleton(height: 64),
          ),
        ),
        error: (_, __) => KynzaErrorState(
          message: 'Impossible de charger les jours bloqués.',
          onRetry: () => ref.invalidate(salonOverridesProvider(salonId)),
        ),
        data: (overrides) {
          final blocked = overrides.where((o) => !o.isAvailable).toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          if (blocked.isEmpty) {
            return KynzaEmptyState(
              icon: Icons.event_available_outlined,
              title: 'Aucun jour bloqué',
              subtitle: "Tous vos jours d'ouverture habituels sont actifs.",
              ctaLabel: 'Retour',
              onCta: () => Navigator.of(context).pop(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: blocked.length,
            itemBuilder: (context, index) {
              final o = blocked[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: KynzaCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${o.date.day}/${o.date.month}/${o.date.year}',
                            ),
                            if (o.reason != null) Text(o.reason!),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () async {
                          final confirmed = await showKynzaConfirmDialog(
                            context,
                            title: 'Débloquer ce jour ?',
                            message:
                                'Ce jour redeviendra ouvert selon vos horaires habituels.',
                            isDestructive: false,
                          );
                          if (confirmed) {
                            await ref
                                .read(availabilityNotifierProvider.notifier)
                                .delete(o.id!, salonId);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
