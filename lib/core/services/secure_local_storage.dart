import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the Supabase auth session (including the refresh token) in the
/// OS Keychain/Keystore via `flutter_secure_storage`, instead of
/// `supabase_flutter`'s own default (`SharedPreferencesLocalStorage` —
/// plain, unencrypted SharedPreferences XML / plist). `flutter_secure_
/// storage` was already a direct pubspec dependency but was never actually
/// wired up anywhere — a real gap found during Phase 5 of the Enterprise
/// Hardening pass (a prior security doc had claimed Keychain/Keystore
/// storage was already in place; it wasn't).
class SecureLocalStorage extends LocalStorage {
  const SecureLocalStorage();

  static const _key = 'kynza_supabase_session';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => (await _storage.read(key: _key)) != null;

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
}
