import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/models/cms_content_model.dart';
import 'package:kynza/features/evolution/cms/data/cms_cache.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kynza_cms_cache_test');
    Hive.init(tempDir.path);
    await Hive.openBox(CmsCache.boxName);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(CmsCache.boxName);
    await tempDir.delete(recursive: true);
  });

  group('CmsCache', () {
    test('returns null for a (type, locale) combination never cached', () {
      expect(CmsCache.get(type: 'help_article', locale: 'fr'), isNull);
    });

    test('round-trips content scoped per (type, locale)', () async {
      final frArticle = CmsContentModel(
        id: 'a1',
        type: 'help_article',
        slug: 'comment-reserver',
        locale: 'fr',
        title: 'Comment réserver',
        bodyMarkdown: 'Ouvrez l\'app et choisissez un créneau.',
        status: 'published',
        createdAt: DateTime(2026, 7, 4),
        updatedAt: DateTime(2026, 7, 4),
      );

      await CmsCache.set(type: 'help_article', locale: 'fr', content: [frArticle]);

      final cachedFr = CmsCache.get(type: 'help_article', locale: 'fr');
      final cachedEn = CmsCache.get(type: 'help_article', locale: 'en');

      expect(cachedFr, isNotNull);
      expect(cachedFr!.single.title, 'Comment réserver');
      expect(cachedEn, isNull);
    });

    test('clear() removes every cached (type, locale) entry', () async {
      await CmsCache.set(
        type: 'announcement',
        locale: 'fr',
        content: [
          CmsContentModel(
            id: 'b1',
            type: 'announcement',
            slug: 'maintenance',
            title: 'Maintenance prévue',
            bodyMarkdown: 'Le service sera indisponible dimanche.',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        ],
      );

      await CmsCache.clear();

      expect(CmsCache.get(type: 'announcement', locale: 'fr'), isNull);
    });
  });
}
