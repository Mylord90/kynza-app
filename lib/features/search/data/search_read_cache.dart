import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/models/search/search_result_item.dart';

/// Last-known search result snapshot per query+filter signature, and the
/// last-known popular-searches list — same convention as [CmsCache]: no
/// generated model serialization exists for [SearchResultItem] (it's a
/// plain view-model class, not a freezed/json_serializable one), so this
/// cache serializes/deserializes it manually.
abstract class SearchReadCache {
  static const boxName = 'kynza_search_cache';
  static const _popularKey = '_popular';

  static Box get _box => Hive.box(boxName);

  static Map<String, dynamic> _toJson(SearchResultItem item) => {
    'id': item.id,
    'type': item.type.name,
    'title': item.title,
    'subtitle': item.subtitle,
    'imageUrl': item.imageUrl,
    'priceBif': item.priceBif,
    'rating': item.rating,
    'province': item.province,
    'salonId': item.salonId,
  };

  static SearchResultItem _fromJson(Map<String, dynamic> json) =>
      SearchResultItem(
        id: json['id'] as String,
        type: SearchResultType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => SearchResultType.salon,
        ),
        title: json['title'] as String,
        subtitle: json['subtitle'] as String?,
        imageUrl: json['imageUrl'] as String?,
        priceBif: json['priceBif'] as int?,
        rating: (json['rating'] as num?)?.toDouble(),
        province: json['province'] as String?,
        salonId: json['salonId'] as String,
      );

  static List<SearchResultItem>? getResults(String signature) {
    final raw = _box.get('q:$signature');
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map((r) => _fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  static Future<void> setResults(
    String signature,
    List<SearchResultItem> results,
  ) => _box.put('q:$signature', results.map(_toJson).toList());

  static List<String>? getPopularSearches() {
    final raw = _box.get(_popularKey);
    if (raw is! List) return null;
    return raw.cast<String>();
  }

  static Future<void> setPopularSearches(List<String> terms) =>
      _box.put(_popularKey, terms);

  static Future<void> clear() => _box.clear();
}
