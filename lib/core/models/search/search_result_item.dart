enum SearchResultType { salon, service }

/// Unified shape for both salons and services so AdvancedSearchScreen can
/// render one results list grouped by [type] without two separate
/// rendering paths.
class SearchResultItem {
  const SearchResultItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.priceBif,
    this.rating,
    this.province,
    required this.salonId,
  });

  final String id;
  final SearchResultType type;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final int? priceBif;
  final double? rating;
  final String? province;

  /// The salon to navigate to on tap — for a salon result this is [id]
  /// itself, for a service result it's the parent salon.
  final String salonId;
}

enum SearchSortBy { relevance, priceAsc, priceDesc, rating }
