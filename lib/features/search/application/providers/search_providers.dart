import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/search/search_result_item.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/repositories/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(),
);

final searchFiltersProvider = StateProvider<SearchFilters>(
  (ref) => const SearchFilters(),
);

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider.autoDispose<List<SearchResultItem>>((ref) {
      final query = ref.watch(searchQueryProvider);
      final filters = ref.watch(searchFiltersProvider);
      if (query.trim().isEmpty && filters.isEmpty) {
        return Future.value(const []);
      }
      return ref.read(searchRepositoryProvider).search(query.trim(), filters);
    });

final popularSearchesProvider = FutureProvider.autoDispose<List<String>>(
  (ref) => ref.read(searchRepositoryProvider).getPopularSearches(),
);
