import 'package:hive_flutter/hive_flutter.dart';

/// Best-effort local record of a `Firebase.initializeApp()` failure at boot.
/// Crashlytics can't record its own initialization failure — it depends on
/// Firebase to exist — so this unencrypted, low-sensitivity box (a raw error
/// string + timestamp, never PII) is the fallback: written unconditionally
/// before Firebase is even attempted, then flushed to Crashlytics as a
/// non-fatal on the next boot where Firebase does come up.
abstract class FirebaseInitFailureLog {
  static const boxName = 'kynza_firebase_init_failures';
  static const _entryKey = 'last_failure';

  static Box get _box => Hive.box(boxName);

  static Future<void> record(Object error) => _box.put(_entryKey, {
    'timestamp': DateTime.now().toIso8601String(),
    'error': error.toString(),
  });

  static Map<String, dynamic>? peek() {
    final entry = _box.get(_entryKey);
    return entry is Map ? entry.cast<String, dynamic>() : null;
  }

  static Future<void> clear() => _box.delete(_entryKey);
}
