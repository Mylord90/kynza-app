import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/models/cms_content_model.dart';
import 'package:kynza/core/models/cms_content_version_model.dart';
import 'package:kynza/core/models/feature_flag_model.dart';
import 'package:kynza/core/permissions/permission_cache.dart';
import 'package:kynza/features/evolution/cms/application/providers/cms_providers.dart';
import 'package:kynza/features/evolution/cms/data/cms_cache.dart';
import 'package:kynza/features/evolution/cms/domain/repositories/cms_repository.dart';
import 'package:kynza/features/evolution/feature_flags/data/feature_flag_cache.dart';

class _FakeCmsRepository implements CmsRepository {
  List<CmsContentModel> published;
  _FakeCmsRepository(this.published);

  @override
  Future<List<CmsContentModel>> getPublished({
    required String type,
    required String locale,
  }) async => published;

  @override
  Future<void> update({
    required String id,
    required String title,
    required String bodyMarkdown,
  }) async {
    published = [
      for (final c in published)
        if (c.id == id) c.copyWith(title: title, bodyMarkdown: bodyMarkdown) else c,
    ];
  }

  @override
  Stream<List<CmsContentModel>> watchPublished() => throw UnimplementedError();
  @override
  Future<List<CmsContentModel>> getAllForAdmin() => throw UnimplementedError();
  @override
  Future<List<CmsContentVersionModel>> getVersions(String contentId) =>
      throw UnimplementedError();
  @override
  Future<void> create({
    required String type,
    required String slug,
    required String locale,
    required String title,
    required String bodyMarkdown,
  }) => throw UnimplementedError();
  @override
  Future<void> setStatus({required String id, required String status}) =>
      throw UnimplementedError();
}

/// CP3 (Enterprise Resilience & Reliability Certification) — proves the two
/// documented cache-expiry designs actually behave the way their own doc
/// comments claim, rather than assuming it from reading the source:
/// `PermissionCache` has a real, enforced 15-minute TTL (mirroring the
/// server-side cache of the same duration); `FeatureFlagCache` has none by
/// deliberate design (a last-known-good offline fallback, per its own doc
/// comment) — both are correct as designed, but CACHE_STRATEGY_REPORT.md's
/// finding is that `PermissionCache.clear()`/`PermissionService
/// .invalidateCache()` exist for an instant local bust on a role change but
/// have zero call sites, so a permission change always waits out the full
/// TTL even though the plumbing for an instant bust already exists.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kynza_cache_strategy_test');
    Hive.init(tempDir.path);
    await Hive.openBox(PermissionCache.boxName);
    await Hive.openBox(FeatureFlagCache.boxName);
    await Hive.openBox(CmsCache.boxName);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(PermissionCache.boxName);
    await Hive.deleteBoxFromDisk(FeatureFlagCache.boxName);
    await Hive.deleteBoxFromDisk(CmsCache.boxName);
    await tempDir.delete(recursive: true);
  });

  test(
    'CMS: editing published content through CmsNotifier.updateContent now '
    'invalidates cmsPublishedProvider (all family instances), so the next '
    'read reflects the edit instead of serving stale cached content — the '
    'gap this checkpoint found and fixed',
    () async {
      final now = DateTime(2026, 1, 1);
      final original = CmsContentModel(
        id: 'c-1',
        type: 'faq',
        slug: 'how-to-book',
        locale: 'fr',
        title: 'Old title',
        bodyMarkdown: 'old body',
        status: 'published',
        createdAt: now,
        updatedAt: now,
      );
      final repo = _FakeCmsRepository([original]);
      final container = ProviderContainer(
        overrides: [cmsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      const params = (type: 'faq', locale: 'fr');
      final before = await container.read(cmsPublishedProvider(params).future);
      expect(before.single.title, 'Old title');

      await container
          .read(cmsNotifierProvider.notifier)
          .updateContent(id: 'c-1', title: 'New title', bodyMarkdown: 'new body');

      final after = await container.read(cmsPublishedProvider(params).future);
      expect(
        after.single.title,
        'New title',
        reason: 'cmsPublishedProvider must be invalidated by the admin edit, '
            'not keep serving the pre-edit snapshot',
      );
    },
  );

  test(
    'PermissionCache: an entry past its stored expiresAt is treated as a '
    'miss, not returned stale — real TTL enforcement, not just a documented '
    'intention',
    () async {
      await PermissionCache.set('owner:s-1:booking.create', true);
      expect(PermissionCache.get('owner:s-1:booking.create'), isTrue);

      // Directly inject an entry whose expiresAt is already in the past —
      // equivalent to real time having advanced 15+ minutes, without
      // actually waiting 15 real minutes in a test.
      final box = Hive.box(PermissionCache.boxName);
      await box.put('owner:s-1:booking.cancel', {
        'value': true,
        'expiresAt': DateTime.now()
            .subtract(const Duration(minutes: 1))
            .millisecondsSinceEpoch,
      });

      expect(
        PermissionCache.get('owner:s-1:booking.cancel'),
        isNull,
        reason: 'an expired entry must be treated as a cache miss, never '
            'returned as if it were still fresh',
      );
    },
  );

  test(
    'FeatureFlagCache: has no expiry concept at all — a snapshot set long '
    '"ago" is returned exactly as fresh as one set a second ago, by design '
    '(last-known-good offline fallback, not a TTL cache)',
    () async {
      final flags = [
        FeatureFlagModel(
          id: 'f-1',
          key: 'test_flag',
          name: 'Test Flag',
          isEnabled: true,
          rolloutPercentage: 100,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];
      await FeatureFlagCache.set(flags);

      // There is no way to simulate "time passing" for this cache because
      // it stores no timestamp at all — that absence is exactly the point
      // being proven: read it back an arbitrary number of times, it never
      // considers itself stale.
      for (var i = 0; i < 3; i++) {
        final result = FeatureFlagCache.get();
        expect(result, isNotNull);
        expect(result!.single.key, 'test_flag');
        expect(result.single.isEnabled, isTrue);
      }
    },
  );
}
