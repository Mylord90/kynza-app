import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/models/cms_content_model.dart';

/// Last-known published CMS content, cached on-device by `type:locale` key
/// so Help Center / announcement banners still render while offline —
/// same "last-cached snapshot, not a blank error" convention as
/// [FeatureFlagCache]/[RemoteConfigCache].
abstract class CmsCache {
  static const boxName = 'kynza_cms_cache';

  static Box get _box => Hive.box(boxName);

  static String _key(String type, String locale) => '$type:$locale';

  static List<CmsContentModel>? get({
    required String type,
    required String locale,
  }) {
    final raw = _box.get(_key(type, locale));
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map((r) => CmsContentModel.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  static Future<void> set({
    required String type,
    required String locale,
    required List<CmsContentModel> content,
  }) {
    return _box.put(
      _key(type, locale),
      content.map((c) => c.toJson()).toList(),
    );
  }

  static Future<void> clear() => _box.clear();
}
