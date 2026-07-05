import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Generates (once) and retrieves the AES-256 key used to encrypt every
/// Hive box that can hold PII: [SessionService]'s `kynza_prefs`, and (since
/// Master Plan CP3) the cold-start read caches — bookings, profile,
/// notifications. The key itself lives in the OS Keychain/Keystore via
/// `flutter_secure_storage`, never in any Hive box it protects.
abstract class HiveEncryptionKeyService {
  static const _keyStorageKey = 'kynza_prefs_hive_aes_key';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<HiveAesCipher> getCipher() async {
    var encoded = await _storage.read(key: _keyStorageKey);
    if (encoded == null) {
      final key = Hive.generateSecureKey();
      encoded = base64UrlEncode(key);
      await _storage.write(key: _keyStorageKey, value: encoded);
    }
    final key = base64Url.decode(encoded);
    return HiveAesCipher(key);
  }
}
