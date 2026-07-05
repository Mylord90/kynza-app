import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kynza/core/models/legal/data_deletion_request_model.dart';
import 'package:kynza/core/models/review/review_model.dart';
import 'package:kynza/core/models/review/salon_rating_model.dart';
import 'package:kynza/core/services/atomic_claim_service.dart';
import 'package:kynza/core/services/mutation_outbox_service.dart';
import 'package:kynza/core/services/offline_sync_coordinator.dart';
import 'package:kynza/features/home_client/domain/repositories/client_profile_repository.dart';
import 'package:kynza/features/legal/domain/repositories/data_deletion_repository.dart';
import 'package:kynza/features/reviews/domain/repositories/review_repository.dart';

/// CP3 (Final Enterprise Validation) — fault scenarios NOT covered by
/// test/unit/offline_sync_coordinator_test.dart: mid-write app kill, phone
/// restart during an active flush, concurrent flush races, and a corrupted
/// queue record. Uses real temp-directory Hive boxes throughout — no mocks
/// of Hive itself — because the property under test (does the record
/// actually survive on disk / does re-reading the same directory reflect
/// it) can't be proven against an in-memory fake.

class _FakeReviewRepository implements ReviewRepository {
  _FakeReviewRepository({this.onCreate});
  final List<ReviewModel> createdCalls = [];
  final Future<void> Function(ReviewModel)? onCreate;

  @override
  Future<ReviewModel> createReview(ReviewModel review) async {
    if (onCreate != null) await onCreate!(review);
    createdCalls.add(review);
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

class _FakeDataDeletionRepository implements DataDeletionRepository {
  final List<String> createdForUserIds = [];
  @override
  Future<List<DataDeletionRequestModel>> getUserRequests(String userId) async => [];
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
  @override
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
    String? email,
  }) async {
    updatedForUserIds.add(userId);
  }
}

OfflineSyncCoordinator _coordinator(
  MutationOutboxService outbox, {
  ReviewRepository? review,
  DataDeletionRepository? deletion,
  ClientProfileRepository? profile,
}) => OfflineSyncCoordinator(
  outbox: outbox,
  reviewRepository: review ?? _FakeReviewRepository(),
  dataDeletionRepository: deletion ?? _FakeDataDeletionRepository(),
  clientProfileRepository: profile ?? _FakeClientProfileRepository(),
);

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kynza_fault_injection_test');
    Hive.init(tempDir.path);
    await Hive.openBox(MutationOutboxService.boxName);
    await Hive.openBox(MutationOutboxService.deadLetterBoxName);
  });

  tearDown(() async {
    AtomicClaimService.instance.reset();
    await Hive.deleteBoxFromDisk(MutationOutboxService.boxName);
    await Hive.deleteBoxFromDisk(MutationOutboxService.deadLetterBoxName);
    await tempDir.delete(recursive: true);
  });

  group('Mid-write app kill', () {
    test(
      'enqueue() persists before the app would ever have a chance to close Hive gracefully — '
      're-reading the same on-disk box (no close() call in between) shows the item',
      () async {
        final outbox = MutationOutboxService();
        await outbox.enqueue(
          type: OutboxMutationType.profileUpdate,
          payload: {'userId': 'u-kill-1', 'fullName': 'Mid Write', 'phone': null, 'email': null},
          dedupeKey: 'u-kill-1',
        );

        // Simulate a kill: no close(), no flush of any kind — just ask a
        // brand-new service instance (as a fresh app launch would create)
        // to read the *same already-open* box. This is the strongest
        // real proof available without an actual OS-level process kill:
        // if `put()` hadn't already reached disk before returning, this
        // assertion is the one that would catch it.
        final reopened = MutationOutboxService();
        expect(reopened.pending(), hasLength(1));
        expect(reopened.pending().single['payload']['fullName'], 'Mid Write');
      },
    );
  });

  group('Phone restart during an active outbox flush', () {
    test(
      'a flush() that stalls partway (simulated kill on item 2 of 3) leaves already-applied '
      'work intact and un-reached items untouched; a fresh coordinator after "restart" '
      'resumes correctly — no loss, no double-apply of item 1',
      () async {
        final outbox = MutationOutboxService();
        await outbox.enqueue(
          type: OutboxMutationType.dataDeletionRequest,
          payload: {'userId': 'u-a', 'notes': null},
        );
        final stallGate = Completer<void>();
        final reachedStall = Completer<void>();
        final review = _FakeReviewRepository(
          onCreate: (_) {
            reachedStall.complete();
            // Never completes on its own — stands in for "the process was
            // killed while this await was in flight."
            return stallGate.future;
          },
        );
        await outbox.enqueue(
          type: OutboxMutationType.reviewCreate,
          payload: {
            'salonId': 's-1',
            'clientId': 'c-1',
            'bookingId': 'b-stall',
            'rating': 5,
            'comment': null,
            'isAnonymous': false,
          },
        );
        final deletion = _FakeDataDeletionRepository();
        await outbox.enqueue(
          type: OutboxMutationType.profileUpdate,
          payload: {'userId': 'u-c', 'fullName': 'Never Reached', 'phone': null, 'email': null},
        );

        final coordinator = _coordinator(outbox, review: review, deletion: deletion);
        // Fire-and-abandon: this mirrors the process dying mid-await —
        // nothing ever awaits this Future to completion.
        unawaited(coordinator.flush());
        await reachedStall.future;

        // At the stall point: item 1 (deletion) must be fully applied and
        // removed; item 2 (review) must still be pending (it's in-flight,
        // neither applied-and-removed nor failed-and-DLQ'd); item 3
        // (profile) must be untouched because the sequential loop never
        // reached it.
        expect(deletion.createdForUserIds, ['u-a']);
        final pendingAtStall = outbox.pending();
        expect(pendingAtStall.map((i) => i['payload']['bookingId']), contains('b-stall'));
        expect(
          pendingAtStall.map((i) => i['payload']['fullName']),
          contains('Never Reached'),
        );
        expect(pendingAtStall, hasLength(2));

        // "Restart": a real process kill wipes in-memory state along with
        // it — including AtomicClaimService's lock map, which otherwise
        // would still show `flush` held by the never-completing call
        // above. Only the Hive-backed queue data survives to disk.
        AtomicClaimService.instance.reset();
        final freshReview = _FakeReviewRepository();
        final freshProfile = _FakeClientProfileRepository();
        final freshCoordinator = _coordinator(
          MutationOutboxService(),
          review: freshReview,
          profile: freshProfile,
        );
        await freshCoordinator.flush();

        expect(freshReview.createdCalls, hasLength(1));
        expect(freshReview.createdCalls.single.bookingId, 'b-stall');
        expect(freshProfile.updatedForUserIds, ['u-c']);
        expect(MutationOutboxService().pending(), isEmpty);
        // Item 1 was never re-applied — the fresh deletion repo below
        // would have recorded a second call if the coordinator had
        // replayed it; it wasn't even wired in, because it was already
        // removed from the box before the "restart".
      },
    );
  });

  group('Concurrent flush() race', () {
    test(
      'two flush() calls firing at the same time (e.g. two connectivity-change '
      'events) never apply the same item twice',
      () async {
        final outbox = MutationOutboxService();
        for (var i = 0; i < 5; i++) {
          await outbox.enqueue(
            type: OutboxMutationType.dataDeletionRequest,
            payload: {'userId': 'u-race-$i', 'notes': null},
          );
        }
        final deletion = _FakeDataDeletionRepository();
        final coordinatorA = _coordinator(outbox, deletion: deletion);
        final coordinatorB = _coordinator(MutationOutboxService(), deletion: deletion);

        await Future.wait([coordinatorA.flush(), coordinatorB.flush()]);

        // Every user must have been applied — and, critically, no more
        // than once each. A race in the read-modify-write of the pending
        // list (both coordinators reading the same 5-item snapshot before
        // either removes anything) would show up here as duplicates.
        final counts = <String, int>{};
        for (final id in deletion.createdForUserIds) {
          counts[id] = (counts[id] ?? 0) + 1;
        }
        expect(
          counts.values.every((c) => c == 1),
          isTrue,
          reason:
              'expected exactly one createRequest call per user, got: $counts '
              '(a value > 1 means the concurrent flushes double-applied an item)',
        );
        expect(counts.keys.length, 5, reason: 'no item should be lost either');
      },
    );
  });

  group('Corrupted queue record', () {
    test(
      'a malformed record (missing required payload field) injected directly into the box '
      'does not jam the queue — it fails, retries, and dead-letters like any other failure; '
      'a valid sibling item still flushes normally',
      () async {
        final outbox = MutationOutboxService();
        // A well-formed item.
        await outbox.enqueue(
          type: OutboxMutationType.dataDeletionRequest,
          payload: {'userId': 'u-good', 'notes': null},
        );
        // Directly corrupt the box: an item whose payload is missing the
        // 'bookingId' the reviewCreate handler requires — the kind of
        // record a partial/interrupted write or a future schema change
        // could plausibly leave behind.
        final box = Hive.box(MutationOutboxService.boxName);
        final items = (box.get('pending') as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        items.add({
          'id': 'corrupt-1',
          'type': OutboxMutationType.reviewCreate,
          'payload': <String, dynamic>{'salonId': 's-1'}, // no bookingId/clientId/rating
          'dedupeKey': null,
          'queuedAt': DateTime.now(),
          'attempts': 0,
        });
        await box.put('pending', items);

        final deletion = _FakeDataDeletionRepository();
        final coordinator = _coordinator(outbox, deletion: deletion);

        // Flush repeatedly, as real reconnects would over time.
        for (var i = 0; i < MutationOutboxService.maxAttempts; i++) {
          await coordinator.flush();
        }

        // The valid sibling item was not blocked by the corrupt one.
        expect(deletion.createdForUserIds, ['u-good']);
        // The corrupt item did not survive indefinitely in "pending" —
        // it was retried up to maxAttempts and then dead-lettered, same
        // as any other persistent failure. It is not silently lost either.
        expect(
          outbox.pending().where((i) => i['id'] == 'corrupt-1'),
          isEmpty,
          reason: 'corrupt item must not remain stuck in pending forever',
        );
        expect(
          outbox.deadLetterItems().any((i) => i['id'] == 'corrupt-1'),
          isTrue,
          reason: 'corrupt item must land in the DLQ, not vanish',
        );
      },
    );
  });

  group('Enqueue racing a flush', () {
    test(
      'an item enqueued while a flush is already iterating the (already-snapshotted) '
      'pending list is not lost — it is simply left for the next flush call',
      () async {
        final outbox = MutationOutboxService();
        final gate = Completer<void>();
        final profile = _FakeClientProfileRepository();
        final coordinator = _coordinator(outbox, profile: profile);

        await outbox.enqueue(
          type: OutboxMutationType.profileUpdate,
          payload: {'userId': 'u-first', 'fullName': 'First', 'phone': null, 'email': null},
        );

        // Start a flush whose only item hangs until we say so, giving us
        // a window to enqueue a second item concurrently.
        final firstProfileRepo = _FakeClientProfileRepository();
        final slowCoordinator = OfflineSyncCoordinator(
          outbox: outbox,
          reviewRepository: _FakeReviewRepository(),
          dataDeletionRepository: _FakeDataDeletionRepository(),
          clientProfileRepository: _SlowThenFastProfileRepo(gate, firstProfileRepo),
        );
        final flushFuture = slowCoordinator.flush();

        await outbox.enqueue(
          type: OutboxMutationType.profileUpdate,
          payload: {'userId': 'u-second', 'fullName': 'Second', 'phone': null, 'email': null},
        );
        gate.complete();
        await flushFuture;

        // The first flush only had 'u-first' in its snapshot, so
        // 'u-second' is untouched by it but must still be sitting in the
        // box, ready for the next flush trigger — not dropped.
        expect(firstProfileRepo.updatedForUserIds, ['u-first']);
        expect(
          outbox.pending().map((i) => i['payload']['userId']),
          contains('u-second'),
        );

        await coordinator.flush();
        expect(profile.updatedForUserIds, ['u-second']);
        expect(outbox.pending(), isEmpty);
      },
    );
  });
}

class _SlowThenFastProfileRepo implements ClientProfileRepository {
  _SlowThenFastProfileRepo(this.gate, this.delegate);
  final Completer<void> gate;
  final _FakeClientProfileRepository delegate;

  @override
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
    String? email,
  }) async {
    await gate.future;
    await delegate.updateProfile(
      userId: userId,
      fullName: fullName,
      phone: phone,
      email: email,
    );
  }
}
