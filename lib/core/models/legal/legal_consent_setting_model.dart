import 'package:freezed_annotation/freezed_annotation.dart';
import '../../enums/app_enums.dart';

part 'legal_consent_setting_model.freezed.dart';
part 'legal_consent_setting_model.g.dart';

class LegalConsentTypeConverter extends JsonConverter<LegalConsentType, String> {
  const LegalConsentTypeConverter();

  static const _toDb = {
    LegalConsentType.marketingEmails: 'marketing_emails',
    LegalConsentType.analytics: 'analytics',
    LegalConsentType.pushNotifications: 'push_notifications',
    LegalConsentType.dataProcessing: 'data_processing',
  };

  @override
  LegalConsentType fromJson(String json) => _toDb.entries
      .firstWhere((e) => e.value == json, orElse: () => _toDb.entries.first)
      .key;

  @override
  String toJson(LegalConsentType object) => _toDb[object]!;
}

@freezed
class LegalConsentSettingModel with _$LegalConsentSettingModel {
  const factory LegalConsentSettingModel({
    String? id,
    required String userId,
    @LegalConsentTypeConverter() required LegalConsentType consentType,
    @Default(false) bool granted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _LegalConsentSettingModel;

  factory LegalConsentSettingModel.fromSupabase(Map<String, dynamic> json) =>
      LegalConsentSettingModel.fromJson(json);

  factory LegalConsentSettingModel.fromJson(Map<String, dynamic> json) =>
      _$LegalConsentSettingModelFromJson(json);
}
