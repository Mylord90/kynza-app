import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/search/search_result_item.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  @override
  Future<List<SearchResultItem>> search(
    String query,
    SearchFilters filters,
  ) async {
    try {
      final results = <SearchResultItem>[];
      // Category/price are service-only concepts — once either is set,
      // salons (which have neither) would just show up unfiltered by
      // them, which reads as broken rather than "no match".
      final hasServiceOnlyFilters =
          filters.categories.isNotEmpty ||
          filters.minPriceBif != null ||
          filters.maxPriceBif != null;
      if (!hasServiceOnlyFilters) {
        results.addAll(await _searchSalons(query, filters));
      }
      results.addAll(await _searchServices(query, filters));
      return _sort(results, filters.sortBy);
    } catch (_) {
      throw const AppException('Impossible de lancer la recherche.');
    }
  }

  Future<List<SearchResultItem>> _searchSalons(
    String query,
    SearchFilters filters,
  ) async {
    var builder = SupabaseService.from(
      'salons',
    ).select().eq('is_online', true).isFilter('deleted_at', null);
    if (query.isNotEmpty) {
      builder = builder.or('name.ilike.%$query%,description.ilike.%$query%');
    }
    if (filters.province != null) {
      builder = builder.eq('province', filters.province!);
    }
    final rows = await builder.limit(30);
    if (rows.isEmpty) return [];

    final ids = rows.map((r) => r['id'] as String).toList();
    final ratingRows = await SupabaseService.from(
      'v_salon_ratings',
    ).select('salon_id, average_rating').inFilter('salon_id', ids);
    final ratingBySalon = {
      for (final r in ratingRows)
        r['salon_id'] as String: (r['average_rating'] as num).toDouble(),
    };

    return rows
        .map((row) {
          final id = row['id'] as String;
          final rating = ratingBySalon[id];
          return SearchResultItem(
            id: id,
            salonId: id,
            type: SearchResultType.salon,
            title: row['name'] as String,
            subtitle: row['province'] as String?,
            imageUrl: row['logo_url'] as String?,
            rating: rating,
            province: row['province'] as String?,
          );
        })
        .where(
          (r) =>
              filters.minRating == null ||
              (r.rating ?? 0) >= filters.minRating!,
        )
        .toList();
  }

  Future<List<SearchResultItem>> _searchServices(
    String query,
    SearchFilters filters,
  ) async {
    var builder = SupabaseService.from('services')
        .select('*, salon:salons!inner(name, province, logo_url, is_online)')
        .eq('is_active', true)
        .eq('salon.is_online', true)
        .isFilter('deleted_at', null);
    if (query.isNotEmpty) {
      builder = builder.ilike('name', '%$query%');
    }
    if (filters.categories.isNotEmpty) {
      builder = builder.inFilter('category', filters.categories);
    }
    if (filters.minPriceBif != null) {
      builder = builder.gte('price_bif', filters.minPriceBif!);
    }
    if (filters.maxPriceBif != null) {
      builder = builder.lte('price_bif', filters.maxPriceBif!);
    }
    if (filters.province != null) {
      builder = builder.eq('salon.province', filters.province!);
    }
    final rows = await builder.limit(30);

    return rows.map((row) {
      final salon = row['salon'] as Map<String, dynamic>?;
      return SearchResultItem(
        id: row['id'] as String,
        salonId: row['salon_id'] as String,
        type: SearchResultType.service,
        title: row['name'] as String,
        subtitle: salon?['name'] as String?,
        imageUrl: salon?['logo_url'] as String?,
        priceBif: row['price_bif'] as int,
        province: salon?['province'] as String?,
      );
    }).toList();
  }

  List<SearchResultItem> _sort(
    List<SearchResultItem> items,
    SearchSortBy sortBy,
  ) {
    final sorted = [...items];
    switch (sortBy) {
      case SearchSortBy.priceAsc:
        sorted.sort((a, b) => (a.priceBif ?? 0).compareTo(b.priceBif ?? 0));
      case SearchSortBy.priceDesc:
        sorted.sort((a, b) => (b.priceBif ?? 0).compareTo(a.priceBif ?? 0));
      case SearchSortBy.rating:
        sorted.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      case SearchSortBy.relevance:
        break;
    }
    return sorted;
  }

  @override
  Future<void> logSearch(String query) async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null || query.trim().length < 2) return;
    try {
      await SupabaseService.from(
        'search_logs',
      ).insert({'user_id': userId, 'query': query.trim()});
    } catch (_) {
      // Best-effort — a failed log must never block search results.
    }
  }

  @override
  Future<List<String>> getPopularSearches() async {
    try {
      final rows = await SupabaseService.from(
        'v_popular_searches',
      ).select('query').limit(10);
      return rows.map((r) => r['query'] as String).toList();
    } catch (_) {
      return [];
    }
  }
}
