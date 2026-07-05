import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/models/review/review_model.dart';
import 'package:kynza/core/models/review/salon_rating_model.dart';
import 'package:kynza/core/providers/app_providers.dart';
import 'package:kynza/core/providers/offline_sync_providers.dart';
import 'package:kynza/core/services/circuit_breaker.dart';
import 'package:kynza/core/services/mutation_outbox_service.dart';
import 'package:kynza/features/reviews/application/providers/review_providers.dart';
import 'package:kynza/features/reviews/domain/repositories/review_repository.dart';

/// CP1 (Enterprise Resilience & Reliability Certification) originally
/// proved a real gap here, distinct from the prior campaign's network-loss/
/// reconnect tests: every offline-queueable write (`ReviewNotifier
/// .createReview`, `ClientProfileNotifier`, `LegalAcceptanceNotifier`, and
/// the data-deletion equivalent — all four share this exact shape, see
/// docs/enterprise-resilience/RESILIENCE_REPORT.md §1) decided "queue vs
/// write directly" using ONLY `connectivityProvider` (OS-level network
/// interface state from `connectivity_plus`), never whether Supabase itself
/// was actually reachable — so "network up, Supabase down/erroring" was
/// indistinguishable from "network up, Supabase fine" until the write was
/// already attempted and threw, by which point it was too late to queue it.
///
/// CP2 closed this gap (docs/enterprise-resilience/CIRCUIT_BREAKER_REPORT.md):
/// the online branch now goes through `DependencyCircuitBreakers.supabase`,
/// whose fallback is the same offline queue — this test now proves the
/// fixed behavior (queued, no exception) rather than the original gap.
class _ThrowingReviewRepository implements ReviewRepository {
  const _ThrowingReviewRepository();

  @override
  Future<ReviewModel> createReview(ReviewModel review) =>
      throw Exception('simulated: Supabase unreachable/erroring, network interface still up');

  @override
  Future<bool> canReview(String bookingId) => throw UnimplementedError();
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

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kynza_dependency_down_test');
    Hive.init(tempDir.path);
    await Hive.openBox(MutationOutboxService.boxName);
    await Hive.openBox(MutationOutboxService.deadLetterBoxName);
    DependencyCircuitBreakers.supabase.reset();
  });

  tearDown(() async {
    DependencyCircuitBreakers.supabase.reset();
    await Hive.deleteBoxFromDisk(MutationOutboxService.boxName);
    await Hive.deleteBoxFromDisk(MutationOutboxService.deadLetterBoxName);
    await tempDir.delete(recursive: true);
  });

  test(
    'network interface reports online but Supabase itself is unreachable: '
    'the write falls back to the offline outbox instead of throwing and '
    'losing the mutation — CP2 closing the gap CP1 found',
    () async {
      final container = ProviderContainer(
        overrides: [
          // Simulates connectivity_plus reporting a live network interface
          // — this is the ONLY signal every offline-queueable write path
          // checks before deciding to write directly vs. queue.
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
          reviewRepositoryProvider.overrideWithValue(const _ThrowingReviewRepository()),
        ],
      );
      addTearDown(container.dispose);

      // Let the StreamProvider emit its first value before reading it —
      // mirrors the real app, where the banner/notifier reads a value
      // that's already resolved by the time a user action fires.
      await container.read(connectivityProvider.future);

      const review = ReviewModel(
        salonId: 's-1',
        clientId: 'c-1',
        bookingId: 'b-1',
        rating: 5,
        comment: null,
        isAnonymous: false,
      );

      // No longer throws: DependencyCircuitBreakers.supabase.run's fallback
      // absorbs the repository's exception and queues the mutation.
      await container.read(reviewNotifierProvider.notifier).createReview(review);

      final outbox = container.read(mutationOutboxServiceProvider);
      expect(
        outbox.pending(),
        hasLength(1),
        reason:
            'FIXED: a Supabase-down-while-online write now falls back to '
            'the offline outbox instead of being silently lost — see '
            'CIRCUIT_BREAKER_REPORT.md',
      );
      expect(outbox.pending().single['payload']['bookingId'], 'b-1');
    },
  );
}
