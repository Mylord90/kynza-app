import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/models/cms_content_model.dart';
import 'package:kynza/core/models/cms_content_version_model.dart';
import 'package:kynza/features/evolution/cms/application/providers/cms_providers.dart';
import 'package:kynza/features/evolution/cms/data/cms_cache.dart';
import 'package:kynza/features/evolution/cms/domain/repositories/cms_repository.dart';

class _FailingCmsRepository implements CmsRepository {
  @override
  Future<List<CmsContentModel>> getPublished({
    required String type,
    required String locale,
  }) => Future<List<CmsContentModel>>.error('network unavailable');

  @override
  Stream<List<CmsContentModel>> watchPublished() => const Stream.empty();

  @override
  Future<List<CmsContentModel>> getAllForAdmin() async => [];

  @override
  Future<List<CmsContentVersionModel>> getVersions(String contentId) async =>
      [];

  @override
  Future<void> create({
    required String type,
    required String slug,
    required String locale,
    required String title,
    required String bodyMarkdown,
  }) async {}

  @override
  Future<void> update({
    required String id,
    required String title,
    required String bodyMarkdown,
  }) async {}

  @override
  Future<void> setStatus({required String id, required String status}) async {}
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kynza_cms_offline_test');
    Hive.init(tempDir.path);
    await Hive.openBox(CmsCache.boxName);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(CmsCache.boxName);
    await tempDir.delete(recursive: true);
  });

  test(
    'cmsPublishedProvider falls back to the last-cached snapshot when the '
    'repository fails (offline) — proven, not just described',
    () async {
      final cached = [
        CmsContentModel(
          id: 'c1',
          type: 'help_article',
          slug: 'deja-en-cache',
          locale: 'fr',
          title: 'Article déjà en cache',
          bodyMarkdown: 'Contenu lu hors-ligne.',
          status: 'published',
          createdAt: DateTime(2026, 7, 4),
          updatedAt: DateTime(2026, 7, 4),
        ),
      ];
      await CmsCache.set(type: 'help_article', locale: 'fr', content: cached);

      final container = ProviderContainer(
        overrides: [
          cmsRepositoryProvider.overrideWithValue(_FailingCmsRepository()),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        cmsPublishedProvider((type: 'help_article', locale: 'fr')).future,
      );

      expect(result, hasLength(1));
      expect(result.single.title, 'Article déjà en cache');
    },
  );
}
