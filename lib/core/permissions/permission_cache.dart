import 'package:hive_flutter/hive_flutter.dart';

/// Local mirror of the 15-minute server-side cache in
/// user_effective_permissions_cache — avoids a round trip for every
/// PermissionGuard rebuild. Same TTL on both sides so a revoked
/// permission never appears "more cached" on-device than on the server.
abstract class PermissionCache {
  static const boxName = 'kynza_permission_cache';
  static const _ttl = Duration(minutes: 15);

  static Box get _box => Hive.box(boxName);

  static bool? get(String key) {
    final entry = _box.get(key);
    if (entry is! Map) return null;
    final expiresAt = entry['expiresAt'] as int?;
    if (expiresAt == null ||
        DateTime.now().millisecondsSinceEpoch > expiresAt) {
      return null;
    }
    return entry['value'] as bool?;
  }

  static Future<void> set(String key, bool value) {
    return _box.put(key, {
      'value': value,
      'expiresAt': DateTime.now().add(_ttl).millisecondsSinceEpoch,
    });
  }

  static Future<void> clear() => _box.clear();
}
