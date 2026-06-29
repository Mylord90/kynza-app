import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/models/search/search_result_item.dart';
import 'package:kynza/features/search/domain/repositories/search_repository.dart';

void main() {
  group('SearchFilters.isEmpty', () {
    test('true for the default (no filters applied)', () {
      expect(const SearchFilters().isEmpty, isTrue);
    });

    test('false once a price filter is set', () {
      expect(const SearchFilters(minPriceBif: 1000).isEmpty, isFalse);
    });

    test('false once a rating filter is set', () {
      expect(const SearchFilters(minRating: 4).isEmpty, isFalse);
    });

    test('false once a category is selected', () {
      expect(
        const SearchFilters(categories: ['Coiffure Homme']).isEmpty,
        isFalse,
      );
    });

    test('false once a province is selected', () {
      expect(
        const SearchFilters(province: 'Bujumbura Mairie').isEmpty,
        isFalse,
      );
    });

    test('false once sort is anything other than relevance', () {
      expect(
        const SearchFilters(sortBy: SearchSortBy.priceAsc).isEmpty,
        isFalse,
      );
    });
  });
}
