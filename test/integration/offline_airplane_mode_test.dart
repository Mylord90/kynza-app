import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/models/review/review_model.dart';
import 'package:kynza/core/models/review/salon_rating_model.dart';
import 'package:kynza/core/providers/app_providers.dart';
import 'package:kynza/core/providers/offline_sync_coordinator_provider.dart';
import 'package:kynza/core/providers/offline_sync_providers.dart';
import 'package:kynza/core/services/mutation_outbox_service.dart';
import 'package:kynza/core/services/offline_sync_coordinator.dart';
import 'package:kynza/features/reviews/application/providers/review_providers.dart';
import 'package:kynza/features/reviews/domain/repositories/review_repository.dart';

/// Airplane-mode simulation for the review-creation flow — one of the 3
/// mutations `OfflineSyncCoordinator` actually queues today (the other two,
/// booking creation and ProxiPay, are deliberately excluded — see
/// docs/OFFLINE_STRATEGY.md). Phase 9, Enterprise Hardening pass.
///
/// This drives the real, production `ReviewNotifier` — not the coordinator
/// directly (already covered by test/unit/offline_sync_coordinator_test.dart's
/// "Review creation — offline enqueue then sync" group, which starts from a
/// synthetic payload, not the notifier's own online/offline branching logic).
///
/// The other two queued flows — profile update (`ClientProfileNotifier`) and
/// data-deletion request (`DataDeletionNotifier`) — read
/// `SupabaseService.auth.currentUser` directly inside the notifier (a
/// pre-existing pattern, documented as a testability gap since Phase 3/6 of
/// this hardening pass: no Supabase test-bootstrap exists in this
/// environment). That call throws before the offline branch is ever
/// reached, so their airplane-mode behavior can only be exercised at the
/// `OfflineSyncCoordinator` level today (already covered by the two other
/// groups in offline_sync_coordinator_test.dart) — not duplicated here.
class _FakeReviewRepository implements ReviewRepository {
  int createCallCount = 0;

  @override
  Future<ReviewModel> createReview(ReviewModel review) async {
    createCallCount++;
    return review;
  }

  @override
  Future<bool> canReview(String bookingId) async => true;

  @override
  Future<ReviewModel> updateReview(String id, int rating, String? comment) =>
      throw UnimplementedError();

  @override
  Future<ReviewModel> replyToReview(String id, String reply) =>
      throw UnimplementedError();

  @override
  Future<List<ReviewModel>> getSalonReviews(String salonId, {int page = 0}) =>
      throw UnimplementedError();

  @override
  Future<SalonRatingModel> getSalonRating(String salonId) =>
      throw UnimplementedError();

  @override
  Future<void> flagReview(String id) => throw UnimplementedError();
}

ReviewModel _draftReview() => const ReviewModel(
  salonId: 'salon-1',
  clientId: 'client-1',
  bookingId: 'booking-1',
  rating: 5,
);

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'kynza_offline_airplane_mode_test',
    );
    Hive.init(tempDir.path);
    await Hive.openBox(MutationOutboxService.boxName);
    await Hive.openBox(MutationOutboxService.deadLetterBoxName);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(MutationOutboxService.boxName);
    await Hive.deleteBoxFromDisk(MutationOutboxService.deadLetterBoxName);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('Review creation — real ReviewNotifier respects airplane mode', () {
    test('offline: queues via the outbox, the online repository is never called', () async {
      final repo = _FakeReviewRepository();
      final container = ProviderContainer(
        overrides: [
          reviewRepositoryProvider.overrideWithValue(repo),
          connectivityProvider.overrideWith((ref) => Stream.value(false)),
        ],
      );
      addTearDown(container.dispose);
      // Let the connectivityProvider stream emit its first (offline) value.
      await container.read(connectivityProvider.future);

      await container
          .read(reviewNotifierProvider.notifier)
          .createReview(_draftReview());

      expect(repo.createCallCount, 0);
      final pending = container
          .read(mutationOutboxServiceProvider)
          .pending(type: OutboxMutationType.reviewCreate);
      expect(pending, hasLength(1));
      expect(pending.single['payload']['bookingId'], 'booking-1');
    });

    test('online: writes directly through the repository, the outbox stays empty', () async {
      final repo = _FakeReviewRepository();
      final container = ProviderContainer(
        overrides: [
          reviewRepositoryProvider.overrideWithValue(repo),
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(connectivityProvider.future);

      await container
          .read(reviewNotifierProvider.notifier)
          .createReview(_draftReview());

      expect(repo.createCallCount, 1);
      final pending = container
          .read(mutationOutboxServiceProvider)
          .pending(type: OutboxMutationType.reviewCreate);
      expect(pending, isEmpty);
    });

    test('offline then reconnect: the queued review flushes exactly once through the same repository', () async {
      final repo = _FakeReviewRepository();
      final container = ProviderContainer(
        overrides: [
          reviewRepositoryProvider.overrideWithValue(repo),
          connectivityProvider.overrideWith((ref) => Stream.value(false)),
        ],
      );
      addTearDown(container.dispose);
      await container.read(connectivityProvider.future);

      await container
          .read(reviewNotifierProvider.notifier)
          .createReview(_draftReview());
      expect(repo.createCallCount, 0);

      // Reconnect and flush — the coordinator replays the queued mutation
      // through the exact same online repository the notifier itself uses.
      await container.read(offlineSyncCoordinatorProvider).flush();

      expect(repo.createCallCount, 1);
      final pending = container
          .read(mutationOutboxServiceProvider)
          .pending(type: OutboxMutationType.reviewCreate);
      expect(pending, isEmpty);
    });
  });
}
