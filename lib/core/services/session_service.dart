import 'package:hive_flutter/hive_flutter.dart';
import '../enums/user_role.dart';

abstract class _HiveKeys {
  static const sessionPersisted = 'session_persisted';
  static const onboardingDone = 'onboarding_done';
  static const role = 'role';
  static const language = 'language';
  static const confidentialMode = 'confidential_mode';
}

/// Hive-based persistence for lightweight app state.
/// Supabase itself persists the auth session (FlutterAuthClientOptions.persistSession);
/// this box only tracks app-level flags layered on top of that session.
class SessionService {
  static const boxName = 'kynza_prefs';

  Box get _box => Hive.box(boxName);

  Future<void> persistSession() => _box.put(_HiveKeys.sessionPersisted, true);

  bool restoreSession() =>
      _box.get(_HiveKeys.sessionPersisted, defaultValue: false) as bool;

  Future<void> clearSession() => _box.delete(_HiveKeys.sessionPersisted);

  Future<void> markOnboardingDone() => _box.put(_HiveKeys.onboardingDone, true);

  bool isOnboardingDone() =>
      _box.get(_HiveKeys.onboardingDone, defaultValue: false) as bool;

  Future<void> saveRole(UserRole role) => _box.put(_HiveKeys.role, role.name);

  UserRole? getRole() {
    final value = _box.get(_HiveKeys.role) as String?;
    return value == null ? null : UserRole.fromString(value);
  }

  Future<void> saveLanguage(String code) => _box.put(_HiveKeys.language, code);

  String getLanguage() =>
      _box.get(_HiveKeys.language, defaultValue: 'fr') as String;

  Future<void> saveConfidentialMode(bool value) =>
      _box.put(_HiveKeys.confidentialMode, value);

  bool getConfidentialMode() =>
      _box.get(_HiveKeys.confidentialMode, defaultValue: false) as bool;
}
