import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/document_template_model.dart';
import '../../data/repositories/template_repository_impl.dart';
import '../../domain/repositories/template_repository.dart';

final templateRepositoryProvider = Provider<TemplateRepository>(
  (ref) => TemplateRepositoryImpl(),
);

typedef TemplateQuery = ({String salonId, String? type});

final templatesProvider = FutureProvider.autoDispose
    .family<List<DocumentTemplateModel>, TemplateQuery>(
      (ref, query) => ref
          .read(templateRepositoryProvider)
          .getTemplates(query.salonId, type: query.type),
    );

final templateNotifierProvider = AsyncNotifierProvider<TemplateNotifier, void>(
  TemplateNotifier.new,
);

class TemplateNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<DocumentTemplateModel> createTemplate({
    required String salonId,
    required String type,
    required String name,
    required String body,
    bool isDefault = false,
  }) async {
    final template = await ref
        .read(templateRepositoryProvider)
        .createTemplate(
          salonId: salonId,
          type: type,
          name: name,
          body: body,
          isDefault: isDefault,
        );
    ref.invalidate(templatesProvider((salonId: salonId, type: null)));
    ref.invalidate(templatesProvider((salonId: salonId, type: type)));
    return template;
  }

  Future<DocumentTemplateModel> updateTemplate({
    required String id,
    required String salonId,
    required String type,
    required String name,
    required String body,
    bool? isDefault,
  }) async {
    final template = await ref
        .read(templateRepositoryProvider)
        .updateTemplate(id: id, name: name, body: body, isDefault: isDefault);
    ref.invalidate(templatesProvider((salonId: salonId, type: null)));
    ref.invalidate(templatesProvider((salonId: salonId, type: type)));
    return template;
  }

  Future<void> deleteTemplate(String id, String salonId, String type) async {
    await ref.read(templateRepositoryProvider).deleteTemplate(id);
    ref.invalidate(templatesProvider((salonId: salonId, type: null)));
    ref.invalidate(templatesProvider((salonId: salonId, type: type)));
  }
}
