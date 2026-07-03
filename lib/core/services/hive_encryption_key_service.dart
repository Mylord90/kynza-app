import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Generates (once) and retrieves the AES-256 key used to encrypt
/// [SessionService]'s Hive box (`kynza_prefs`) — the one box holding
/// PII-adjacent values (pending invitation/referral tokens, recent
/// searches). The key itself lives in the OS Keychain/Keystore via
/// `flutter_secure_storage`, never in the Hive box it protects.
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
