import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/models/service_model.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../application/providers/service_providers.dart';
import '../widgets/service_card.dart';
import '../widgets/service_category_chip.dart';
import 'service_form_screen.dart';

class ServicesListScreen extends ConsumerStatefulWidget {
  const ServicesListScreen({super.key});

  @override
  ConsumerState<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends ConsumerState<ServicesListScreen> {
  String? _categoryFilter;
  final Map<String, Timer> _pendingDeletes = {};

  @override
  void dispose() {
    for (final t in _pendingDeletes.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _swipeDelete(ServiceModel service) {
    final id = service.id!;
    setState(() {});
    _pendingDeletes[id] = Timer(const Duration(seconds: 3), () {
      ref
          .read(serviceNotifierProvider.notifier)
          .softDelete(id)
          .catchError((_) {});
      _pendingDeletes.remove(id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Text('« ${service.name} » supprimé.'),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () {
            _pendingDeletes[id]?.cancel();
            _pendingDeletes.remove(id);
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salon = ref.watch(ownerSalonProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Services')),
      floatingActionButton: salon == null
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ServiceFormScreen(salonId: salon.id),
                ),
              ),
              child: const Icon(Icons.add, color: AppColors.background),
            ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          if (salon != null) Expanded(child: _buildBody(salon.id)),
        ],
      ),
    );
  }

  Widget _buildBody(String salonId) {
    final servicesAsync = ref.watch(salonServicesProvider(salonId));

    return servicesAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 5,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: KynzaSkeleton(height: 80),
        ),
      ),
      error: (error, _) => KynzaErrorState(
        message: 'Impossible de charger les services.',
        onRetry: () => ref.invalidate(salonServicesProvider(salonId)),
      ),
      data: (services) {
        if (services.isEmpty) {
          return KynzaEmptyState(
            icon: Icons.content_cut,
            title: 'Aucun service',
            subtitle:
                'Ajoutez vos prestations pour commencer à recevoir des RDV.',
            ctaLabel: 'Ajouter un service',
            onCta: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ServiceFormScreen(salonId: salonId),
              ),
            ),
          );
        }

        final visible = services
            .where((s) => !_pendingDeletes.containsKey(s.id))
            .where(
              (s) => _categoryFilter == null || s.category == _categoryFilter,
            )
            .toList();

        final categories = services.map((s) => s.category).toSet().toList();

        return Column(
          children: [
            if (categories.length > 1)
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ServiceCategoryChip(
                        label: 'Toutes',
                        isSelected: _categoryFilter == null,
                        onTap: () => setState(() => _categoryFilter = null),
                      ),
                    ),
                    for (final c in categories)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ServiceCategoryChip(
                          label: c,
                          isSelected: _categoryFilter == c,
                          onTap: () => setState(() => _categoryFilter = c),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final service = visible[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Dismissible(
                      key: ValueKey(service.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(AppSpacing.md),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                      ),
                      onDismissed: (_) => _swipeDelete(service),
                      child: ServiceCard(
                        service: service,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ServiceFormScreen(
                              salonId: salonId,
                              existing: service,
                            ),
                          ),
                        ),
                        onToggleActive: (active) => ref
                            .read(serviceNotifierProvider.notifier)
                            .toggleActive(service.id!, active)
                            .catchError((_) {}),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
