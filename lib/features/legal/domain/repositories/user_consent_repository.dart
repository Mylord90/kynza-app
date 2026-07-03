import '../../../../core/enums/app_enums.dart';
import '../../../../core/models/legal/legal_consent_setting_model.dart';
import '../../../../core/models/legal/user_legal_acceptance_model.dart';

abstract class UserConsentRepository {
  Future<List<UserLegalAcceptanceModel>> getUserAcceptances(String userId);

  Future<UserLegalAcceptanceModel> acceptDocumentVersion({
    required String userId,
    required String documentVersionId,
    String? appVersion,
    String? platform,
  });

  Future<List<LegalConsentSettingModel>> getUserConsents(String userId);

  Future<LegalConsentSettingModel> setConsent({
    required String userId,
    required LegalConsentType consentType,
    required bool granted,
  });
}
