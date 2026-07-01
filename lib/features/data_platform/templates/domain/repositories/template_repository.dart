import '../../../../../core/models/document_template_model.dart';

abstract class TemplateRepository {
  Future<List<DocumentTemplateModel>> getTemplates(
    String salonId, {
    String? type,
  });

  Future<DocumentTemplateModel> createTemplate({
    required String salonId,
    required String type,
    required String name,
    required String body,
    bool isDefault = false,
  });

  Future<DocumentTemplateModel> updateTemplate({
    required String id,
    required String name,
    required String body,
    bool? isDefault,
  });

  Future<void> deleteTemplate(String id);

  Future<String?> renderTemplate(
    String templateId,
    Map<String, String> variables,
  );
}
