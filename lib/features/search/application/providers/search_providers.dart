import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/search/search_result_item.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../data/search_read_cache.dart';
import '../../domain/repositories/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(),
);

final searchFiltersProvider = StateProvider<SearchFilters>(
  (ref) => const SearchFilters(),
);

final searchQueryProvider = StateProvider<String>((ref) => '');

String _filtersSignature(String query, SearchFilters filters) =>
    '$query|${filters.minPriceBif}|${filters.maxPriceBif}|${filters.minRating}|'
    '${filters.categories.join(",")}|${filters.province}|${filters.sortBy.name}';

/// Cold-start-offline fix (Master Plan CP3, `BUSINESS_CONTINUITY_REPORT.md`)
/// — same "try live, mirror to cache, fall back to last cached snapshot on
/// any error" convention as `cmsPublishedProvider`.
final searchResultsProvider =
    FutureProvider.autoDispose<List<SearchResultItem>>((ref) async {
      final query = ref.watch(searchQueryProvider);
      final filters = ref.watch(searchFiltersProvider);
      if (query.trim().isEmpty && filters.isEmpty) {
        return const [];
      }
      final signature = _filtersSignature(query.trim(), filters);
      try {
        final results = await ref
            .read(searchRepositoryProvider)
            .search(query.trim(), filters);
        await SearchReadCache.setResults(signature, results);
        return results;
      } catch (_) {
        return SearchReadCache.getResults(signature) ?? const [];
      }
    });

final popularSearchesProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  try {
    final terms = await ref.read(searchRepositoryProvider).getPopularSearches();
    await SearchReadCache.setPopularSearches(terms);
    return terms;
  } catch (_) {
    return SearchReadCache.getPopularSearches() ?? const [];
  }
});
