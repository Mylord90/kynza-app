import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/enums/app_enums.dart';
import 'package:kynza/core/models/legal/data_deletion_request_model.dart';
import 'package:kynza/core/models/review/review_model.dart';
import 'package:kynza/core/models/review/salon_rating_model.dart';
import 'package:kynza/core/services/mutation_outbox_service.dart';
import 'package:kynza/core/services/offline_sync_coordinator.dart';
import 'package:kynza/features/home_client/domain/repositories/client_profile_repository.dart';
import 'package:kynza/features/legal/domain/repositories/data_deletion_repository.dart';
import 'package:kynza/features/reviews/domain/repositories/review_repository.dart';

class _FakeReviewRepository implements ReviewRepository {
  _FakeReviewRepository({Set<String> existingReviewBookingIds = const {}})
    : existingReviewBookingIds = {...existingReviewBookingIds};

  final Set<String> existingReviewBookingIds;
  final List<ReviewModel> createdCalls = [];

  @override
  Future<ReviewModel> createReview(ReviewModel review) async {
    if (existingReviewBookingIds.contains(review.bookingId)) {
      throw Exception('duplicate booking_id — should never be called');
    }
    createdCalls.add(review);
    existingReviewBookingIds.add(review.bookingId);
    return review;
  }

  @override
  Future<bool> canReview(String bookingId) async =>
      !existingReviewBookingIds.contains(bookingId);

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

class _FakeDataDeletionRepository implements DataDeletionRepository {
  _FakeDataDeletionRepository({this.existingRequests = const []});

  final List<DataDeletionRequestModel> existingRequests;
  final List<String> createdForUserIds = [];

  @override
  Future<List<DataDeletionRequestModel>> getUserRequests(String userId) async =>
      existingRequests;

  @override
  Future<DataDeletionRequestModel> createRequest({
    required String userId,
    String? notes,
  }) async {
    createdForUserIds.add(userId);
    return DataDeletionRequestModel(userId: userId, notes: notes);
  }
}

class _FakeClientProfileRepository implements ClientProfileRepository {
  final List<String> updatedForUserIds = [];
  String? lastFullName;

  @override
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
    String? email,
  }) async {
    updatedForUserIds.add(userId);
    lastFullName = fullName;
  }
}

void main() {
  late Directory tempDir;
  late MutationOutboxService outbox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kynza_mutation_outbox_test');
    Hive.init(tempDir.path);
    await Hive.openBox(MutationOutboxService.boxName);
    await Hive.openBox(MutationOutboxService.deadLetterBoxName);
    outbox = MutationOutboxService();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(MutationOutboxService.boxName);
    await Hive.deleteBoxFromDisk(MutationOutboxService.deadLetterBoxName);
    await tempDir.delete(recursive: true);
  });

  group('Review creation — offline enqueue then sync', () {
    test(
      'a queued offline review produces exactly one server-side createReview call on reconnect',
      () async {
        final reviewRepo = _FakeReviewRepository();
        final coordinator = OfflineSyncCoordinator(
          outbox: outbox,
          reviewRepository: reviewRepo,
          dataDeletionRepository: _FakeDataDeletionRepository(),
          clientProfileRepository: _FakeClientProfileRepository(),
        );

        // Simulate: offline, user submits a review.
        await outbox.enqueue(
          type: OutboxMutationType.reviewCreate,
          payload: {
            'salonId': 's-1',
            'clientId': 'c-1',
            'bookingId': 'b-1',
            'rating': 5,
            'comment': 'Great!',
            'isAnonymous': false,
          },
        );
        expect(reviewRepo.createdCalls, isEmpty);

        await coordinator.flush();

        expect(reviewRepo.createdCalls, hasLength(1));
        expect(reviewRepo.createdCalls.single.bookingId, 'b-1');
        expect(outbox.pending(), isEmpty);
      },
    );

    test(
      'if the review already exists by the time of sync (canReview=false), '
      'the coordinator discards the item WITHOUT calling createReview again',
      () async {
        final reviewRepo = _FakeReviewRepository(
          existingReviewBookingIds: {'b-1'},
        );
        final coordinator = OfflineSyncCoordinator(
          outbox: outbox,
          reviewRepository: reviewRepo,
          dataDeletionRepository: _FakeDataDeletionRepository(),
          clientProfileRepository: _FakeClientProfileRepository(),
        );

        await outbox.enqueue(
          type: OutboxMutationType.reviewCreate,
          payload: {
            'salonId': 's-1',
            'clientId': 'c-1',
            'bookingId': 'b-1',
            'rating': 5,
            'comment': null,
            'isAnonymous': false,
          },
        );

        await coordinator.flush();

        // createReview was never called (would have thrown in the fake) —
        // proves the duplicate-avoidance check runs before replay.
        expect(reviewRepo.createdCalls, isEmpty);
        expect(outbox.pending(), isEmpty);
      },
    );
  });

  group('Profile update — offline enqueue then sync', () {
    test(
      'a queued offline profile edit produces exactly one server-side update on reconnect',
      () async {
        final profileRepo = _FakeClientProfileRepository();
        final coordinator = OfflineSyncCoordinator(
          outbox: outbox,
          reviewRepository: _FakeReviewRepository(),
          dataDeletionRepository: _FakeDataDeletionRepository(),
          clientProfileRepository: profileRepo,
        );

        await outbox.enqueue(
          type: OutboxMutationType.profileUpdate,
          payload: {
            'userId': 'u-1',
            'fullName': 'Jane Doe',
            'phone': null,
            'email': null,
          },
          dedupeKey: 'u-1',
        );

        await coordinator.flush();

        expect(profileRepo.updatedForUserIds, ['u-1']);
        expect(profileRepo.lastFullName, 'Jane Doe');
        expect(outbox.pending(), isEmpty);
      },
    );

    test(
      'two offline edits for the same user only ever replay the latest one '
      '(last-write-wins via dedupeKey)',
      () async {
        final profileRepo = _FakeClientProfileRepository();
        final coordinator = OfflineSyncCoordinator(
          outbox: outbox,
          reviewRepository: _FakeReviewRepository(),
          dataDeletionRepository: _FakeDataDeletionRepository(),
          clientProfileRepository: profileRepo,
        );

        await outbox.enqueue(
          type: OutboxMutationType.profileUpdate,
          payload: {'userId': 'u-1', 'fullName': 'First Edit', 'phone': null, 'email': null},
          dedupeKey: 'u-1',
        );
        await outbox.enqueue(
          type: OutboxMutationType.profileUpdate,
          payload: {'userId': 'u-1', 'fullName': 'Second Edit', 'phone': null, 'email': null},
          dedupeKey: 'u-1',
        );

        // Only one item was ever queued — the second enqueue replaced it.
        expect(outbox.pending(), hasLength(1));

        await coordinator.flush();

        // Exactly one server-side update call, with the LATEST value.
        expect(profileRepo.updatedForUserIds, hasLength(1));
        expect(profileRepo.lastFullName, 'Second Edit');
      },
    );
  });

  group('Data deletion request — offline enqueue then sync', () {
    test(
      'a queued offline deletion request produces exactly one server-side create on reconnect',
      () async {
        final deletionRepo = _FakeDataDeletionRepository();
        final coordinator = OfflineSyncCoordinator(
          outbox: outbox,
          reviewRepository: _FakeReviewRepository(),
          dataDeletionRepository: deletionRepo,
          clientProfileRepository: _FakeClientProfileRepository(),
        );

        await outbox.enqueue(
          type: OutboxMutationType.dataDeletionRequest,
          payload: {'userId': 'u-1', 'notes': null},
        );

        await coordinator.flush();

        expect(deletionRepo.createdForUserIds, ['u-1']);
        expect(outbox.pending(), isEmpty);
      },
    );

    test(
      'if a pending request already exists for this user by sync time, '
      'the coordinator discards the item WITHOUT creating a duplicate',
      () async {
        final deletionRepo = _FakeDataDeletionRepository(
          existingRequests: [
            const DataDeletionRequestModel(
              userId: 'u-1',
              status: DataDeletionStatus.pending,
            ),
          ],
        );
        final coordinator = OfflineSyncCoordinator(
          outbox: outbox,
          reviewRepository: _FakeReviewRepository(),
          dataDeletionRepository: deletionRepo,
          clientProfileRepository: _FakeClientProfileRepository(),
        );

        await outbox.enqueue(
          type: OutboxMutationType.dataDeletionRequest,
          payload: {'userId': 'u-1', 'notes': null},
        );

        await coordinator.flush();

        expect(deletionRepo.createdForUserIds, isEmpty);
        expect(outbox.pending(), isEmpty);
      },
    );
  });

  group('Dead-letter queue — shared bookkeeping across all mutation types', () {
    test(
      'a review-create item that fails every attempt lands in the DLQ, '
      'not lost and not retried forever',
      () async {
        final coordinator = OfflineSyncCoordinator(
          outbox: outbox,
          reviewRepository: _AlwaysThrowingReviewRepository(),
          dataDeletionRepository: _FakeDataDeletionRepository(),
          clientProfileRepository: _FakeClientProfileRepository(),
        );

        await outbox.enqueue(
          type: OutboxMutationType.reviewCreate,
          payload: {
            'salonId': 's-1',
            'clientId': 'c-1',
            'bookingId': 'b-1',
            'rating': 5,
            'comment': null,
            'isAnonymous': false,
          },
        );

        for (var i = 0; i < MutationOutboxService.maxAttempts; i++) {
          await coordinator.flush();
        }

        expect(outbox.pending(), isEmpty);
        expect(outbox.deadLetterItems(), hasLength(1));
        expect(
          outbox.deadLetterItems().single['type'],
          OutboxMutationType.reviewCreate,
        );
      },
    );
  });
}

class _AlwaysThrowingReviewRepository implements ReviewRepository {
  @override
  Future<bool> canReview(String bookingId) async => true;
  @override
  Future<ReviewModel> createReview(ReviewModel review) =>
      throw Exception('simulated persistent failure');
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
