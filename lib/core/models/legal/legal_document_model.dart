import 'package:freezed_annotation/freezed_annotation.dart';
import '../../enums/app_enums.dart';

part 'legal_document_model.freezed.dart';
part 'legal_document_model.g.dart';

class LegalDocumentTypeConverter extends JsonConverter<LegalDocumentType, String> {
  const LegalDocumentTypeConverter();

  static const _toDb = {
    LegalDocumentType.privacyPolicy: 'privacy_policy',
    LegalDocumentType.termsOfService: 'terms_of_service',
    LegalDocumentType.cookiePolicy: 'cookie_policy',
    LegalDocumentType.acceptableUsePolicy: 'acceptable_use_policy',
    LegalDocumentType.refundPolicy: 'refund_policy',
    LegalDocumentType.communityGuidelines: 'community_guidelines',
    LegalDocumentType.dataDeletionPolicy: 'data_deletion_policy',
    LegalDocumentType.supportPolicy: 'support_policy',
    LegalDocumentType.legalNotices: 'legal_notices',
  };

  @override
  LegalDocumentType fromJson(String json) => _toDb.entries
      .firstWhere((e) => e.value == json, orElse: () => _toDb.entries.first)
      .key;

  @override
  String toJson(LegalDocumentType object) => _toDb[object]!;
}

@freezed
class LegalDocumentModel with _$LegalDocumentModel {
  const factory LegalDocumentModel({
    String? id,
    required String slug,
    @LegalDocumentTypeConverter() required LegalDocumentType type,
    String? currentVersionId,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _LegalDocumentModel;

  factory LegalDocumentModel.fromSupabase(Map<String, dynamic> json) =>
      LegalDocumentModel.fromJson(json);

  factory LegalDocumentModel.fromJson(Map<String, dynamic> json) =>
      _$LegalDocumentModelFromJson(json);
}
