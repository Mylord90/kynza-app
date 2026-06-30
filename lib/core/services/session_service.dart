import 'package:hive_flutter/hive_flutter.dart';
import '../enums/user_role.dart';

abstract class _HiveKeys {
  static const sessionPersisted = 'session_persisted';
  static const onboardingDone = 'onboarding_done';
  static const role = 'role';
  static const language = 'language';
  static const confidentialMode = 'confidential_mode';
  static const pendingInvitationToken = 'pending_invitation_token';
  static const pendingReferralToken = 'pending_referral_token';
  static const journeyDismissedSalonId = 'journey_dismissed_salon_id';
  static const recentSearches = 'recent_searches';
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

  bool hasStoredLanguage() => _box.containsKey(_HiveKeys.language);

  Future<void> saveConfidentialMode(bool value) =>
      _box.put(_HiveKeys.confidentialMode, value);

  bool getConfidentialMode() =>
      _box.get(_HiveKeys.confidentialMode, defaultValue: false) as bool;

  /// Holds a staff invitation token across the register/complete-profile
  /// detour a brand-new staff member takes before they have a session to
  /// call accept-invitation with — see AcceptInvitationScreen.
  Future<void> savePendingInvitationToken(String token) =>
      _box.put(_HiveKeys.pendingInvitationToken, token);

  String? getPendingInvitationToken() =>
      _box.get(_HiveKeys.pendingInvitationToken) as String?;

  Future<void> clearPendingInvitationToken() =>
      _box.delete(_HiveKeys.pendingInvitationToken);

  /// Same as [savePendingInvitationToken], for a referral link tapped by
  /// a brand-new/logged-out user — see ReferralClaimScreen.
  Future<void> savePendingReferralToken(String token) =>
      _box.put(_HiveKeys.pendingReferralToken, token);

  String? getPendingReferralToken() =>
      _box.get(_HiveKeys.pendingReferralToken) as String?;

  Future<void> clearPendingReferralToken() =>
      _box.delete(_HiveKeys.pendingReferralToken);

  /// Once dismissed at 100%, the owner journey card never resurfaces for
  /// that salon — only one salon is ever dismissed at a time in V1.
  Future<void> dismissJourneyCard(String salonId) =>
      _box.put(_HiveKeys.journeyDismissedSalonId, salonId);

  bool isJourneyCardDismissed(String salonId) =>
      _box.get(_HiveKeys.journeyDismissedSalonId) == salonId;

  static const _maxRecentSearches = 10;

  List<String> getRecentSearches() =>
      (_box.get(_HiveKeys.recentSearches) as List?)?.cast<String>() ?? const [];

  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final current = getRecentSearches().toList()
      ..remove(trimmed)
      ..insert(0, trimmed);
    await _box.put(
      _HiveKeys.recentSearches,
      current.take(_maxRecentSearches).toList(),
    );
  }

  Future<void> clearRecentSearches() => _box.delete(_HiveKeys.recentSearches);
}
