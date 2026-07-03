import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/legal/legal_document_model.dart';
import '../../../../core/models/legal/legal_document_version_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/legal_document_repository.dart';

class LegalDocumentRepositoryImpl implements LegalDocumentRepository {
  static const _documentsTable = 'legal_documents';
  static const _versionsTable = 'legal_document_versions';

  @override
  Future<List<LegalDocumentModel>> getActiveDocuments() async {
    try {
      final rows = await SupabaseService.from(_documentsTable)
          .select()
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('type');
      return rows.map(LegalDocumentModel.fromSupabase).toList();
    } catch (_) {
      throw const AppException(
        'Impossible de charger les documents légaux.',
      );
    }
  }

  @override
  Future<LegalDocumentModel?> getDocumentBySlug(String slug) async {
    final row = await SupabaseService.from(_documentsTable)
        .select()
        .eq('slug', slug)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return row == null ? null : LegalDocumentModel.fromSupabase(row);
  }

  @override
  Future<LegalDocumentModel?> getDocumentById(String id) async {
    final row = await SupabaseService.from(_documentsTable)
        .select()
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return row == null ? null : LegalDocumentModel.fromSupabase(row);
  }

  @override
  Future<LegalDocumentVersionModel?> getVersionById(String id) async {
    final row = await SupabaseService.from(_versionsTable)
        .select()
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return row == null ? null : LegalDocumentVersionModel.fromSupabase(row);
  }

  @override
  Future<LegalDocumentVersionModel?> getCurrentVersion(
    String documentId, {
    String locale = 'fr',
  }) async {
    final row = await SupabaseService.from(_versionsTable)
        .select()
        .eq('document_id', documentId)
        .eq('locale', locale)
        .eq('is_current', true)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return row == null ? null : LegalDocumentVersionModel.fromSupabase(row);
  }

  @override
  Future<List<LegalDocumentVersionModel>> getVersionHistory(
    String documentId, {
    String locale = 'fr',
  }) async {
    final rows = await SupabaseService.from(_versionsTable)
        .select()
        .eq('document_id', documentId)
        .eq('locale', locale)
        .isFilter('deleted_at', null)
        .order('version_number', ascending: false);
    return rows.map(LegalDocumentVersionModel.fromSupabase).toList();
  }
}
