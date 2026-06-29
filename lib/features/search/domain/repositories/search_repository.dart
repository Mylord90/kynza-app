import '../../../../core/models/search/search_result_item.dart';

class SearchFilters {
  const SearchFilters({
    this.minPriceBif,
    this.maxPriceBif,
    this.minRating,
    this.categories = const [],
    this.province,
    this.sortBy = SearchSortBy.relevance,
  });

  final int? minPriceBif;
  final int? maxPriceBif;
  final int? minRating;
  final List<String> categories;
  final String? province;
  final SearchSortBy sortBy;

  bool get isEmpty =>
      minPriceBif == null &&
      maxPriceBif == null &&
      minRating == null &&
      categories.isEmpty &&
      province == null &&
      sortBy == SearchSortBy.relevance;
}

abstract class SearchRepository {
  Future<List<SearchResultItem>> search(String query, SearchFilters filters);
  Future<void> logSearch(String query);
  Future<List<String>> getPopularSearches();
}
