import '../../../../../core/models/cms_content_model.dart';
import '../../../../../core/models/cms_content_version_model.dart';

abstract class CmsRepository {
  /// Published content of [type] in [locale] — the client-facing read path.
  Future<List<CmsContentModel>> getPublished({
    required String type,
    required String locale,
  });

  /// Realtime-subscribed published catalog (any type/locale) — a publish
  /// action reaches connected clients without an app redeploy.
  Stream<List<CmsContentModel>> watchPublished();

  /// Admin: every row regardless of status, for the CRUD screen.
  Future<List<CmsContentModel>> getAllForAdmin();

  Future<List<CmsContentVersionModel>> getVersions(String contentId);

  Future<void> create({
    required String type,
    required String slug,
    required String locale,
    required String title,
    required String bodyMarkdown,
  });

  Future<void> update({
    required String id,
    required String title,
    required String bodyMarkdown,
  });

  Future<void> setStatus({required String id, required String status});
}
