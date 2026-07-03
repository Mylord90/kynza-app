import '../../../../core/enums/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/legal/legal_consent_setting_model.dart';
import '../../../../core/models/legal/user_legal_acceptance_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/user_consent_repository.dart';

class UserConsentRepositoryImpl implements UserConsentRepository {
  static const _acceptancesTable = 'user_legal_acceptances';
  static const _consentsTable = 'legal_consent_settings';

  @override
  Future<List<UserLegalAcceptanceModel>> getUserAcceptances(
    String userId,
  ) async {
    final rows = await SupabaseService.from(_acceptancesTable)
        .select()
        .eq('user_id', userId)
        .order('accepted_at', ascending: false);
    return rows.map(UserLegalAcceptanceModel.fromSupabase).toList();
  }

  @override
  Future<UserLegalAcceptanceModel> acceptDocumentVersion({
    required String userId,
    required String documentVersionId,
    String? appVersion,
    String? platform,
  }) async {
    try {
      // Idempotent: re-accepting the same version the user already accepted
      // returns the original row rather than erroring on the UNIQUE
      // (user_id, document_version_id) constraint — accepting is not an
      // action a screen should ever be able to fail on if already done.
      final row = await SupabaseService.from(_acceptancesTable)
          .upsert({
            'user_id': userId,
            'document_version_id': documentVersionId,
            if (appVersion != null) 'app_version': appVersion,
            if (platform != null) 'platform': platform,
          }, onConflict: 'user_id,document_version_id', ignoreDuplicates: false)
          .select()
          .single();
      return UserLegalAcceptanceModel.fromSupabase(row);
    } catch (_) {
      throw const AppException(
        "Impossible d'enregistrer votre acceptation.",
      );
    }
  }

  @override
  Future<List<LegalConsentSettingModel>> getUserConsents(
    String userId,
  ) async {
    final rows = await SupabaseService.from(_consentsTable)
        .select()
        .eq('user_id', userId)
        .isFilter('deleted_at', null);
    return rows.map(LegalConsentSettingModel.fromSupabase).toList();
  }

  @override
  Future<LegalConsentSettingModel> setConsent({
    required String userId,
    required LegalConsentType consentType,
    required bool granted,
  }) async {
    try {
      const converter = LegalConsentTypeConverter();
      final row = await SupabaseService.from(_consentsTable)
          .upsert({
            'user_id': userId,
            'consent_type': converter.toJson(consentType),
            'granted': granted,
          }, onConflict: 'user_id,consent_type')
          .select()
          .single();
      return LegalConsentSettingModel.fromSupabase(row);
    } catch (_) {
      throw const AppException(
        'Impossible de mettre à jour cette préférence.',
      );
    }
  }
}
