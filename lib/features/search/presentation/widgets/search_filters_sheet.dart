import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/burundi_provinces.dart';
import '../../../../core/constants/service_categories.dart';
import '../../../../core/models/search/search_result_item.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../domain/repositories/search_repository.dart';

const _maxPriceBif = 200000.0;

class SearchFiltersSheet extends StatefulWidget {
  const SearchFiltersSheet({super.key, required this.initial});

  final SearchFilters initial;

  @override
  State<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<SearchFiltersSheet> {
  late RangeValues _priceRange;
  late int _minRating;
  late Set<String> _categories;
  late String? _province;
  late SearchSortBy _sortBy;

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
      (widget.initial.minPriceBif ?? 0).toDouble(),
      (widget.initial.maxPriceBif ?? _maxPriceBif).toDouble(),
    );
    _minRating = widget.initial.minRating ?? 0;
    _categories = widget.initial.categories.toSet();
    _province = widget.initial.province;
    _sortBy = widget.initial.sortBy;
  }

  void _apply() {
    Navigator.of(context).pop(
      SearchFilters(
        minPriceBif: _priceRange.start > 0 ? _priceRange.start.round() : null,
        maxPriceBif: _priceRange.end < _maxPriceBif
            ? _priceRange.end.round()
            : null,
        minRating: _minRating > 0 ? _minRating : null,
        categories: _categories.toList(),
        province: _province,
        sortBy: _sortBy,
      ),
    );
  }

  void _reset() {
    setState(() {
      _priceRange = const RangeValues(0, _maxPriceBif);
      _minRating = 0;
      _categories = {};
      _province = null;
      _sortBy = SearchSortBy.relevance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filtres', style: AppTypography.h2),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Réinitialiser'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Prix (FBu) — ${_priceRange.start.round()} à ${_priceRange.end.round()}',
              style: AppTypography.h3,
            ),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: _maxPriceBif,
              divisions: 20,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _priceRange = v),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Note minimum', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    onPressed: () =>
                        setState(() => _minRating = _minRating == i ? 0 : i),
                    icon: Icon(
                      i <= _minRating ? Icons.star : Icons.star_border,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Catégories', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final c in ServiceCategories.all)
                  FilterChip(
                    label: Text(c),
                    selected: _categories.contains(c),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _categories.add(c);
                      } else {
                        _categories.remove(c);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Province', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            KynzaDropdown<String?>(
              hint: 'Toutes les provinces',
              value: _province,
              items: const [null, ...BurundiProvinces.provinces],
              itemLabel: (p) => p ?? 'Toutes les provinces',
              onChanged: (v) => setState(() => _province = v),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Trier par', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final sort in SearchSortBy.values)
                  ChoiceChip(
                    label: Text(_sortLabel(sort)),
                    selected: _sortBy == sort,
                    onSelected: (_) => setState(() => _sortBy = sort),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            KynzaButton(label: 'Appliquer', onPressed: _apply),
          ],
        ),
      ),
    );
  }

  String _sortLabel(SearchSortBy sort) => switch (sort) {
    SearchSortBy.relevance => 'Pertinence',
    SearchSortBy.priceAsc => 'Prix ↑',
    SearchSortBy.priceDesc => 'Prix ↓',
    SearchSortBy.rating => 'Note',
  };
}
