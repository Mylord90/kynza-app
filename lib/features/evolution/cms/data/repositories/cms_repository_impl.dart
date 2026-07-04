import '../../../../../core/models/cms_content_model.dart';
import '../../../../../core/models/cms_content_version_model.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../domain/repositories/cms_repository.dart';

class CmsRepositoryImpl implements CmsRepository {
  @override
  Future<List<CmsContentModel>> getPublished({
    required String type,
    required String locale,
  }) async {
    final rows = await SupabaseService.from('cms_content')
        .select()
        .eq('type', type)
        .eq('locale', locale)
        .eq('status', 'published')
        .order('title');
    return rows.map((r) => CmsContentModel.fromJson(r)).toList();
  }

  @override
  Stream<List<CmsContentModel>> watchPublished() {
    return SupabaseService.client
        .from('cms_content')
        .stream(primaryKey: ['id'])
        .map(
          (rows) => rows
              .where((r) => r['status'] == 'published' && r['deleted_at'] == null)
              .map(CmsContentModel.fromJson)
              .toList(),
        );
  }

  @override
  Future<List<CmsContentModel>> getAllForAdmin() async {
    final rows = await SupabaseService.from(
      'cms_content',
    ).select().order('type').order('slug');
    return rows.map((r) => CmsContentModel.fromJson(r)).toList();
  }

  @override
  Future<List<CmsContentVersionModel>> getVersions(String contentId) async {
    final rows = await SupabaseService.from('cms_content_versions')
        .select()
        .eq('content_id', contentId)
        .order('version_number', ascending: false);
    return rows.map((r) => CmsContentVersionModel.fromJson(r)).toList();
  }

  @override
  Future<void> create({
    required String type,
    required String slug,
    required String locale,
    required String title,
    required String bodyMarkdown,
  }) async {
    await SupabaseService.from('cms_content').insert({
      'type': type,
      'slug': slug,
      'locale': locale,
      'title': title,
      'body_markdown': bodyMarkdown,
      'status': 'draft',
    });
  }

  @override
  Future<void> update({
    required String id,
    required String title,
    required String bodyMarkdown,
  }) async {
    await SupabaseService.from('cms_content')
        .update({'title': title, 'body_markdown': bodyMarkdown})
        .eq('id', id);
  }

  @override
  Future<void> setStatus({required String id, required String status}) async {
    await SupabaseService.from('cms_content').update({
      'status': status,
      'published_at': status == 'published'
          ? DateTime.now().toIso8601String()
          : null,
    }).eq('id', id);
  }
}
