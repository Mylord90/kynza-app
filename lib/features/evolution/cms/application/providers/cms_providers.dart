import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/models/cms_content_model.dart';
import '../../../../../core/models/cms_content_version_model.dart';
import '../../data/cms_cache.dart';
import '../../data/repositories/cms_repository_impl.dart';
import '../../domain/repositories/cms_repository.dart';

final cmsRepositoryProvider = Provider<CmsRepository>(
  (ref) => CmsRepositoryImpl(),
);

/// Offline-safe client read path: fetches published content for
/// (type, locale), mirrors it into [CmsCache], and falls back to the last
/// cached snapshot on any error (never a blank error state).
final cmsPublishedProvider = FutureProvider.family<
  List<CmsContentModel>,
  ({String type, String locale})
>((ref, params) async {
  try {
    final content = await ref
        .read(cmsRepositoryProvider)
        .getPublished(type: params.type, locale: params.locale);
    await CmsCache.set(type: params.type, locale: params.locale, content: content);
    return content;
  } catch (_) {
    return CmsCache.get(type: params.type, locale: params.locale) ?? const [];
  }
});

final cmsAdminListProvider = FutureProvider<List<CmsContentModel>>(
  (ref) => ref.read(cmsRepositoryProvider).getAllForAdmin(),
);

final cmsVersionsProvider = FutureProvider.family<
  List<CmsContentVersionModel>,
  String
>((ref, contentId) => ref.read(cmsRepositoryProvider).getVersions(contentId));

class CmsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// CP3 (docs/enterprise-resilience/CACHE_STRATEGY_REPORT.md §4): every
  /// mutation here also invalidates `cmsPublishedProvider` (all family
  /// instances — calling `ref.invalidate` on a `.family` provider with no
  /// argument invalidates every cached instance of it), not just
  /// `cmsAdminListProvider`. Previously only the admin list was
  /// invalidated, so the client-facing read path (and its `CmsCache` Hive
  /// mirror, refreshed by that same provider) kept serving pre-edit content
  /// until something else happened to rebuild that exact family key.
  Future<void> create({
    required String type,
    required String slug,
    required String locale,
    required String title,
    required String bodyMarkdown,
  }) async {
    await ref
        .read(cmsRepositoryProvider)
        .create(
          type: type,
          slug: slug,
          locale: locale,
          title: title,
          bodyMarkdown: bodyMarkdown,
        );
    ref.invalidate(cmsAdminListProvider);
    ref.invalidate(cmsPublishedProvider);
  }

  Future<void> updateContent({
    required String id,
    required String title,
    required String bodyMarkdown,
  }) async {
    await ref
        .read(cmsRepositoryProvider)
        .update(id: id, title: title, bodyMarkdown: bodyMarkdown);
    ref.invalidate(cmsAdminListProvider);
    ref.invalidate(cmsPublishedProvider);
  }

  Future<void> setStatus({required String id, required String status}) async {
    await ref.read(cmsRepositoryProvider).setStatus(id: id, status: status);
    ref.invalidate(cmsAdminListProvider);
    ref.invalidate(cmsPublishedProvider);
  }
}

final cmsNotifierProvider = AsyncNotifierProvider<CmsNotifier, void>(
  CmsNotifier.new,
);
