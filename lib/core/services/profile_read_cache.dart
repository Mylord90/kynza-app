import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

/// Last-known own-profile snapshot, cached on-device by user id — same
/// convention as [CmsCache]/[BookingReadCache]: `currentUserProfileProvider`
/// is a plain one-shot `FutureProvider`, so a genuine network error (unlike
/// a realtime stream) is actually thrown and catchable here.
abstract class ProfileReadCache {
  static const boxName = 'kynza_profile_cache';

  static Box get _box => Hive.box(boxName);

  static UserProfile? get(String userId) {
    final raw = _box.get(userId);
    if (raw is! Map) return null;
    return UserProfile.fromJson(Map<String, dynamic>.from(raw));
  }

  static Future<void> set(String userId, UserProfile profile) =>
      _box.put(userId, profile.toJson());

  static Future<void> clear() => _box.clear();
}
