import 'package:freezed_annotation/freezed_annotation.dart';

part 'legal_document_version_model.freezed.dart';
part 'legal_document_version_model.g.dart';

@freezed
class LegalDocumentVersionModel with _$LegalDocumentVersionModel {
  const factory LegalDocumentVersionModel({
    String? id,
    required String documentId,
    required int versionNumber,
    @Default('fr') String locale,
    required String contentMarkdown,
    DateTime? publishedAt,
    @Default(false) bool isCurrent,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _LegalDocumentVersionModel;

  factory LegalDocumentVersionModel.fromSupabase(Map<String, dynamic> json) =>
      LegalDocumentVersionModel.fromJson(json);

  factory LegalDocumentVersionModel.fromJson(Map<String, dynamic> json) =>
      _$LegalDocumentVersionModelFromJson(json);
}
