import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/search/search_result_item.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../../booking/presentation/screens/salon_detail_screen.dart';
import '../../application/providers/search_providers.dart';
import '../../domain/repositories/search_repository.dart';
import '../widgets/search_filters_sheet.dart';

class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  ConsumerState<AdvancedSearchScreen> createState() =>
      _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchQueryProvider.notifier).state = value;
      if (value.trim().length >= 2) {
        ref.read(searchRepositoryProvider).logSearch(value.trim());
        ref.read(sessionServiceProvider).addRecentSearch(value.trim());
      }
    });
  }

  void _selectQuery(String query) {
    _searchCtrl.text = query;
    ref.read(searchQueryProvider.notifier).state = query;
  }

  Future<void> _openFilters() async {
    final current = ref.read(searchFiltersProvider);
    final result = await showKynzaBottomSheet<SearchFilters>(
      context,
      builder: (_) => SearchFiltersSheet(initial: current),
    );
    if (result != null) {
      ref.read(searchFiltersProvider.notifier).state = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final recentSearches = ref
        .watch(sessionServiceProvider)
        .getRecentSearches();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.searchAdvancedTitle),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: filters.isEmpty ? null : AppColors.primary,
            ),
            tooltip: context.l10n.searchFiltersTitle,
            onPressed: _openFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: KynzaTextField(
              hint: context.l10n.searchAdvancedHint,
              controller: _searchCtrl,
              prefixWidget: const Icon(Icons.search, size: 18),
              onChanged: _onChanged,
            ),
          ),
          Expanded(
            child: query.trim().isEmpty && filters.isEmpty
                ? _SuggestionsBody(
                    recentSearches: recentSearches,
                    onTapQuery: _selectQuery,
                    onClearRecent: () => ref
                        .read(sessionServiceProvider)
                        .clearRecentSearches()
                        .then((_) => setState(() {})),
                  )
                : resultsAsync.when(
                    loading: () => ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: 5,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: KynzaSkeleton(height: 72),
                      ),
                    ),
                    error: (_, __) => KynzaErrorState(
                      message: context.l10n.searchLoadError,
                      onRetry: () => ref.invalidate(searchResultsProvider),
                    ),
                    data: (results) {
                      if (results.isEmpty) {
                        return KynzaEmptyState(
                          icon: Icons.search_off,
                          title: context.l10n.searchNoResults,
                          subtitle: context.l10n.searchNoResultsSubtitle,
                          ctaLabel: context.l10n.commonBack,
                          onCta: _noop,
                        );
                      }
                      final salons = results
                          .where((r) => r.type == SearchResultType.salon)
                          .toList();
                      final services = results
                          .where((r) => r.type == SearchResultType.service)
                          .toList();
                      return RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        onRefresh: () async =>
                            ref.invalidate(searchResultsProvider),
                        child: ListView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          children: [
                            if (salons.isNotEmpty) ...[
                              Text(
                                context.l10n.searchSalonsSectionLabel,
                                style: AppTypography.h3,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              for (final r in salons) _ResultTile(item: r),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                            if (services.isNotEmpty) ...[
                              Text(
                                context.l10n.searchServicesSectionLabel,
                                style: AppTypography.h3,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              for (final r in services) _ResultTile(item: r),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}

class _SuggestionsBody extends ConsumerWidget {
  const _SuggestionsBody({
    required this.recentSearches,
    required this.onTapQuery,
    required this.onClearRecent,
  });

  final List<String> recentSearches;
  final void Function(String) onTapQuery;
  final VoidCallback onClearRecent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularAsync = ref.watch(popularSearchesProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.searchRecentLabel, style: AppTypography.h3),
              TextButton(
                onPressed: onClearRecent,
                child: Text(context.l10n.searchClearButton),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final q in recentSearches)
                ActionChip(
                  avatar: const Icon(Icons.history, size: 16),
                  label: Text(q),
                  onPressed: () => onTapQuery(q),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        popularAsync.maybeWhen(
          data: (popular) => popular.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.searchPopularLabel,
                      style: AppTypography.h3,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final q in popular)
                          ActionChip(
                            avatar: const Icon(Icons.trending_up, size: 16),
                            label: Text(q),
                            onPressed: () => onTapQuery(q),
                          ),
                      ],
                    ),
                  ],
                ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.item});

  final SearchResultItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: KynzaCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SalonDetailScreen(salonId: item.salonId),
          ),
        ),
        child: Row(
          children: [
            KynzaAvatar(fullName: item.title, avatarUrl: item.imageUrl),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: AppTypography.h3),
                  if (item.subtitle != null)
                    Text(item.subtitle!, style: AppTypography.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (item.priceBif != null)
                  Text(
                    CurrencyFormatter.formatBif(item.priceBif!),
                    style: AppTypography.bodySmall,
                  ),
                if (item.rating != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      Text(
                        item.rating!.toStringAsFixed(1),
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
