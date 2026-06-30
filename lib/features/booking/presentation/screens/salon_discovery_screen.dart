import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/service_categories.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../salon/application/providers/salon_providers.dart';
import '../../../services/presentation/widgets/service_category_chip.dart';
import '../widgets/salon_card.dart';
import 'salon_detail_screen.dart';

class SalonDiscoveryScreen extends ConsumerStatefulWidget {
  const SalonDiscoveryScreen({super.key});

  @override
  ConsumerState<SalonDiscoveryScreen> createState() =>
      _SalonDiscoveryScreenState();
}

class _SalonDiscoveryScreenState extends ConsumerState<SalonDiscoveryScreen> {
  final _searchCtrl = TextEditingController();
  String? _category;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final salonsAsync = ref.watch(discoverSalonsProvider);
    final categoryIdsAsync = _category == null
        ? null
        : ref.watch(salonIdsByCategoryProvider(_category!));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.bookingDiscoveryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.bookingDiscoveryAdvancedSearchTooltip,
            onPressed: () => context.push(RouteNames.search),
          ),
        ],
      ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: KynzaTextField(
              hint: l10n.bookingDiscoverySearchHint,
              controller: _searchCtrl,
              prefixWidget: const Icon(Icons.search, size: 18),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ServiceCategoryChip(
                    label: l10n.bookingDiscoveryAllCategories,
                    isSelected: _category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                ),
                for (final c in ServiceCategories.all)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ServiceCategoryChip(
                      label: c,
                      isSelected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: salonsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: 4,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: KynzaSkeleton(height: 160),
                ),
              ),
              error: (_, __) => KynzaErrorState(
                message: l10n.bookingDiscoveryLoadError,
                onRetry: () => ref.invalidate(discoverSalonsProvider),
              ),
              data: (salons) {
                final categoryIds = categoryIdsAsync?.valueOrNull;
                final filtered = salons.where((s) {
                  final matchesQuery =
                      _query.isEmpty || s.name.toLowerCase().contains(_query);
                  final matchesCategory =
                      _category == null ||
                      (categoryIds?.contains(s.id) ?? true);
                  return matchesQuery && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return KynzaEmptyState(
                    icon: Icons.storefront_outlined,
                    title: l10n.bookingDiscoveryEmptyTitle,
                    subtitle: l10n.bookingDiscoveryEmptySubtitle,
                    ctaLabel: l10n.bookingDiscoveryResetButton,
                    onCta: () => setState(() {
                      _query = '';
                      _category = null;
                      _searchCtrl.clear();
                    }),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final salon = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: SalonCard(
                        salon: salon,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SalonDetailScreen(salonId: salon.id),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
