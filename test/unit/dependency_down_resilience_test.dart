import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/models/review/review_model.dart';
import 'package:kynza/core/models/review/salon_rating_model.dart';
import 'package:kynza/core/providers/app_providers.dart';
import 'package:kynza/core/providers/offline_sync_providers.dart';
import 'package:kynza/core/services/mutation_outbox_service.dart';
import 'package:kynza/features/reviews/application/providers/review_providers.dart';
import 'package:kynza/features/reviews/domain/repositories/review_repository.dart';

/// CP1 (Enterprise Resilience & Reliability Certification) — proves a real
/// gap distinct from the prior campaign's network-loss/reconnect tests:
/// every offline-queueable write (`ReviewNotifier.createReview`,
/// `ClientProfileNotifier`, `LegalAcceptanceNotifier`, and the data-deletion
/// equivalent — all four share this exact shape, see
/// docs/enterprise-resilience/RESILIENCE_REPORT.md §1) decides "queue vs
/// write directly" using ONLY `connectivityProvider` (OS-level network
/// interface state from `connectivity_plus`). None of them check whether
/// Supabase itself is actually reachable. So "network up, Supabase down/
/// erroring" — a real, common failure mode, not a hypothetical — is
/// indistinguishable from "network up, Supabase fine" until the write is
/// already attempted and throws, and by then it's too late to queue it:
/// the exception surfaces directly to the UI as an error and the mutation
/// is never retried automatically.
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
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(MutationOutboxService.boxName);
    await Hive.deleteBoxFromDisk(MutationOutboxService.deadLetterBoxName);
    await tempDir.delete(recursive: true);
  });

  test(
    'network interface reports online but Supabase itself is unreachable: '
    'the write is attempted directly (never queued), throws, and is lost '
    'from the retry/outbox mechanism entirely — the app has no way to '
    'distinguish "dependency down" from "dependency fine" ahead of time',
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

      await expectLater(
        container.read(reviewNotifierProvider.notifier).createReview(review),
        throwsA(isA<Exception>()),
      );

      // The defining gap: this mutation is now gone. It was never queued
      // (the online branch was taken, since the network interface really
      // was up), and the exception was surfaced as a bare error rather
      // than falling back to the offline outbox — no automatic retry will
      // ever happen once Supabase recovers.
      final outbox = container.read(mutationOutboxServiceProvider);
      expect(
        outbox.pending(),
        isEmpty,
        reason:
            'CONFIRMED GAP: a Supabase-down-while-online write is silently '
            'lost rather than queued for retry — see RESILIENCE_REPORT.md',
      );
    },
  );
}
