import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/models/feature_flag_model.dart';

/// Last-known feature flag catalog, cached on-device so the app can still
/// evaluate flags while offline or before the first Realtime snapshot
/// arrives. No TTL: a stale flag list is still a reasonable fallback (it
/// simply degrades to the previous behavior until connectivity returns),
/// consistent with this app's "last-cached snapshot, not a blank error"
/// offline convention.
abstract class FeatureFlagCache {
  static const boxName = 'kynza_feature_flag_cache';
  static const _key = 'flags';

  static Box get _box => Hive.box(boxName);

  static List<FeatureFlagModel>? get() {
    final raw = _box.get(_key);
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map((r) => FeatureFlagModel.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  static Future<void> set(List<FeatureFlagModel> flags) {
    return _box.put(_key, flags.map((f) => f.toJson()).toList());
  }

  static Future<void> clear() => _box.clear();
}
