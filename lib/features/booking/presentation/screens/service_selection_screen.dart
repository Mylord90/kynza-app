import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../services/application/providers/service_providers.dart';
import '../../application/providers/booking_flow_provider.dart';
import '../widgets/service_booking_card.dart';
import 'practitioner_selection_screen.dart';

class ServiceSelectionScreen extends ConsumerWidget {
  const ServiceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salon = ref.watch(bookingFlowProvider).selectedSalon;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Choisir un service')),
      body: salon == null
          ? const KynzaErrorState(
              message: 'Aucun salon sélectionné.',
              onRetry: _noop,
            )
          : Consumer(
              builder: (context, ref, _) {
                final servicesAsync = ref.watch(
                  salonServicesProvider(salon.id),
                );
                return servicesAsync.when(
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: 5,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md),
                      child: KynzaSkeleton(height: 72),
                    ),
                  ),
                  error: (_, __) => KynzaErrorState(
                    message: 'Impossible de charger les services.',
                    onRetry: () =>
                        ref.invalidate(salonServicesProvider(salon.id)),
                  ),
                  data: (services) {
                    final active = services.where((s) => s.isActive).toList();
                    if (active.isEmpty) {
                      return const KynzaEmptyState(
                        icon: Icons.content_cut,
                        title: 'Aucun service disponible',
                        subtitle: 'Ce salon n\'a pas encore publié de service.',
                        ctaLabel: 'Retour',
                        onCta: _noop,
                      );
                    }
                    final byCategory = <String, List<dynamic>>{};
                    for (final s in active) {
                      byCategory.putIfAbsent(s.category, () => []).add(s);
                    }
                    return ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        for (final entry in byCategory.entries) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            child: Text(entry.key, style: AppTypography.h3),
                          ),
                          for (final service in entry.value)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: ServiceBookingCard(
                                service: service,
                                onTap: () {
                                  ref
                                      .read(bookingFlowProvider.notifier)
                                      .selectService(service);
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PractitionerSelectionScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

void _noop() {}
