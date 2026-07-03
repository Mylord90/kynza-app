import '../../../../core/models/legal/legal_document_model.dart';
import '../../../../core/models/legal/legal_document_version_model.dart';

abstract class LegalDocumentRepository {
  Future<List<LegalDocumentModel>> getActiveDocuments();
  Future<LegalDocumentModel?> getDocumentBySlug(String slug);
  Future<LegalDocumentModel?> getDocumentById(String id);
  Future<LegalDocumentVersionModel?> getVersionById(String id);
  Future<LegalDocumentVersionModel?> getCurrentVersion(
    String documentId, {
    String locale = 'fr',
  });
  Future<List<LegalDocumentVersionModel>> getVersionHistory(
    String documentId, {
    String locale = 'fr',
  });
}
