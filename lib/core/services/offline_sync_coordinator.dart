import '../../features/home_client/domain/repositories/client_profile_repository.dart';
import '../../features/legal/domain/repositories/data_deletion_repository.dart';
import '../../features/reviews/domain/repositories/review_repository.dart';
import '../enums/app_enums.dart';
import '../models/review/review_model.dart';
import '../services/crash_reporting_service.dart';
import '../services/mutation_outbox_service.dart';

/// Mutation type tags stored in [MutationOutboxService] payloads.
abstract class OutboxMutationType {
  static const reviewCreate = 'review_create';
  static const profileUpdate = 'profile_update';
  static const dataDeletionRequest = 'data_deletion_request';
}

/// Flushes [MutationOutboxService]'s queue on reconnect, dispatching each
/// item to the right handler by [OutboxMutationType]. Same retry/DLQ
/// bookkeeping as `LegalAcceptanceService.flushQueue` (3 failed attempts →
/// dead-letter), generalized across the 3 mutation kinds this queue
/// backs — booking creation is deliberately NOT one of them (see
/// docs/OFFLINE_STRATEGY.md §3: slot availability is server-authoritative
/// and can't be resolved offline, and the booking flow navigates to
/// payment using a real server-issued booking id that doesn't exist until
/// the write succeeds).
class OfflineSyncCoordinator {
  OfflineSyncCoordinator({
    required this.outbox,
    required this.reviewRepository,
    required this.dataDeletionRepository,
    required this.clientProfileRepository,
  });

  final MutationOutboxService outbox;
  final ReviewRepository reviewRepository;
  final DataDeletionRepository dataDeletionRepository;
  final ClientProfileRepository clientProfileRepository;

  Future<void> flush() async {
    for (final item in outbox.pending()) {
      final id = item['id'] as String;
      final type = item['type'] as String;
      final payload = (item['payload'] as Map).cast<String, dynamic>();
      try {
        final alreadySatisfied = await _isAlreadySatisfied(type, payload);
        if (!alreadySatisfied) {
          await _apply(type, payload);
        }
        await outbox.remove(id);
      } catch (e, st) {
        try {
          CrashReportingService.recordError(e, st);
        } catch (_) {
          // Never let a Crashlytics failure block the retry/DLQ bookkeeping.
        }
        final attempts = await outbox.recordFailedAttempt(id);
        if (attempts >= MutationOutboxService.maxAttempts) {
          await outbox.moveToDeadLetter(id);
        }
      }
    }
  }

  /// Checks whether this mutation's real-world effect already exists
  /// server-side — e.g. a review for this booking, or a still-pending
  /// deletion request for this user — so a flush that partially succeeded
  /// on a prior attempt (network dropped after the write landed but
  /// before the client saw success) doesn't insert a duplicate on retry.
  /// Profile updates have no such check: an UPDATE is idempotent by
  /// nature, so re-applying it is always safe.
  Future<bool> _isAlreadySatisfied(
    String type,
    Map<String, dynamic> payload,
  ) async {
    switch (type) {
      case OutboxMutationType.reviewCreate:
        final canStillReview = await reviewRepository.canReview(
          payload['bookingId'] as String,
        );
        return !canStillReview;
      case OutboxMutationType.dataDeletionRequest:
        final requests = await dataDeletionRepository.getUserRequests(
          payload['userId'] as String,
        );
        return requests.any(
          (r) => r.status == DataDeletionStatus.pending,
        );
      default:
        return false;
    }
  }

  Future<void> _apply(String type, Map<String, dynamic> payload) async {
    switch (type) {
      case OutboxMutationType.reviewCreate:
        await reviewRepository.createReview(
          ReviewModel(
            salonId: payload['salonId'] as String,
            clientId: payload['clientId'] as String,
            bookingId: payload['bookingId'] as String,
            rating: payload['rating'] as int,
            comment: payload['comment'] as String?,
            isAnonymous: payload['isAnonymous'] as bool? ?? false,
          ),
        );
        return;
      case OutboxMutationType.profileUpdate:
        await clientProfileRepository.updateProfile(
          userId: payload['userId'] as String,
          fullName: payload['fullName'] as String,
          phone: payload['phone'] as String?,
          email: payload['email'] as String?,
        );
        return;
      case OutboxMutationType.dataDeletionRequest:
        await dataDeletionRepository.createRequest(
          userId: payload['userId'] as String,
          notes: payload['notes'] as String?,
        );
        return;
    }
  }
}
