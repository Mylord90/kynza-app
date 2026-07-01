import '../../../../../core/errors/app_exception.dart';
import '../../../../../core/models/document_template_model.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../domain/repositories/template_repository.dart';

class TemplateRepositoryImpl implements TemplateRepository {
  @override
  Future<List<DocumentTemplateModel>> getTemplates(
    String salonId, {
    String? type,
  }) async {
    try {
      var q = SupabaseService.from(
        'document_templates',
      ).select().eq('salon_id', salonId).isFilter('deleted_at', null);
      if (type != null) q = q.eq('type', type);
      final rows = await q.order('type').order('is_default', ascending: false);
      return rows.map(DocumentTemplateModel.fromJson).toList();
    } catch (_) {
      throw const AppException('Impossible de charger les modèles.');
    }
  }

  @override
  Future<DocumentTemplateModel> createTemplate({
    required String salonId,
    required String type,
    required String name,
    required String body,
    bool isDefault = false,
  }) async {
    try {
      final row = await SupabaseService.from('document_templates')
          .insert({
            'salon_id': salonId,
            'type': type,
            'name': name,
            'body': body,
            'is_default': isDefault,
          })
          .select()
          .single();
      return DocumentTemplateModel.fromJson(row);
    } catch (_) {
      throw const AppException('Impossible de créer le modèle.');
    }
  }

  @override
  Future<DocumentTemplateModel> updateTemplate({
    required String id,
    required String name,
    required String body,
    bool? isDefault,
  }) async {
    try {
      final updates = <String, dynamic>{'name': name, 'body': body};
      if (isDefault != null) updates['is_default'] = isDefault;
      final row = await SupabaseService.from(
        'document_templates',
      ).update(updates).eq('id', id).select().single();
      return DocumentTemplateModel.fromJson(row);
    } catch (_) {
      throw const AppException('Impossible de mettre à jour le modèle.');
    }
  }

  @override
  Future<void> deleteTemplate(String id) async {
    try {
      await SupabaseService.from(
        'document_templates',
      ).update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', id);
    } catch (_) {
      throw const AppException('Impossible de supprimer le modèle.');
    }
  }

  @override
  Future<String?> renderTemplate(
    String templateId,
    Map<String, String> variables,
  ) async {
    try {
      final result = await SupabaseService.client.rpc(
        'render_template',
        params: {'p_template_id': templateId, 'p_variables': variables},
      );
      return result as String?;
    } catch (_) {
      throw const AppException('Impossible de générer le document.');
    }
  }
}
