import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/models/remote_config_entry_model.dart';

/// Last-known remote config snapshot, cached on-device so config values
/// stay usable offline or before the first Realtime snapshot arrives — the
/// same "last-cached snapshot, not a blank error" convention used by
/// [FeatureFlagCache].
abstract class RemoteConfigCache {
  static const boxName = 'kynza_remote_config_cache';
  static const _key = 'entries';

  static Box get _box => Hive.box(boxName);

  static List<RemoteConfigEntryModel>? get() {
    final raw = _box.get(_key);
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map(
          (r) => RemoteConfigEntryModel.fromJson(Map<String, dynamic>.from(r)),
        )
        .toList();
  }

  static Future<void> set(List<RemoteConfigEntryModel> entries) {
    return _box.put(_key, entries.map((e) => e.toJson()).toList());
  }

  static dynamic getValue(String key) {
    final entries = get();
    if (entries == null) return null;
    for (final entry in entries) {
      if (entry.key == key) return entry.valueJson;
    }
    return null;
  }

  static Future<void> clear() => _box.clear();
}
