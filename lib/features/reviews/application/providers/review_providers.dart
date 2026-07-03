import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/review/review_model.dart';
import '../../../../core/models/review/salon_rating_model.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/offline_sync_providers.dart';
import '../../../../core/services/offline_sync_coordinator.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../domain/repositories/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepositoryImpl(),
);

final salonReviewsProvider = FutureProvider.autoDispose
    .family<List<ReviewModel>, String>(
      (ref, salonId) =>
          ref.watch(reviewRepositoryProvider).getSalonReviews(salonId),
    );

final salonRatingProvider = FutureProvider.autoDispose
    .family<SalonRatingModel, String>(
      (ref, salonId) =>
          ref.watch(reviewRepositoryProvider).getSalonRating(salonId),
    );

final canReviewProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, bookingId) => ref.watch(reviewRepositoryProvider).canReview(bookingId),
);

final reviewNotifierProvider = AsyncNotifierProvider<ReviewNotifier, void>(
  ReviewNotifier.new,
);

class ReviewNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  /// Offline-first: writes directly when online; when offline, queues via
  /// the generic mutation outbox (replayed by `OfflineSyncCoordinator` on
  /// reconnect — see `KynzaOfflineBanner`). A queued review is naturally
  /// safe to replay: `reviews.booking_id UNIQUE` means a duplicate insert
  /// on retry always fails cleanly, and the coordinator checks
  /// `canReview()` before replaying to avoid even attempting a doomed
  /// duplicate insert.
  Future<void> createReview(ReviewModel review) async {
    state = const AsyncLoading();
    try {
      final isOnline = ref.read(connectivityProvider).value ?? false;
      if (!isOnline) {
        await ref.read(mutationOutboxServiceProvider).enqueue(
          type: OutboxMutationType.reviewCreate,
          payload: {
            'salonId': review.salonId,
            'clientId': review.clientId,
            'bookingId': review.bookingId,
            'rating': review.rating,
            'comment': review.comment,
            'isAnonymous': review.isAnonymous,
          },
        );
      } else {
        await ref.read(reviewRepositoryProvider).createReview(review);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.invalidate(salonReviewsProvider(review.salonId));
      ref.invalidate(salonRatingProvider(review.salonId));
      ref.invalidate(canReviewProvider(review.bookingId));
    }
  }

  Future<void> updateReview(
    String salonId,
    String id,
    int rating,
    String? comment,
  ) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(reviewRepositoryProvider)
          .updateReview(id, rating, comment);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.invalidate(salonReviewsProvider(salonId));
      ref.invalidate(salonRatingProvider(salonId));
    }
  }

  Future<void> replyToReview(String salonId, String id, String reply) async {
    state = const AsyncLoading();
    try {
      await ref.read(reviewRepositoryProvider).replyToReview(id, reply);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.invalidate(salonReviewsProvider(salonId));
    }
  }

  Future<void> flagReview(String salonId, String id) async {
    try {
      await ref.read(reviewRepositoryProvider).flagReview(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      ref.invalidate(salonReviewsProvider(salonId));
    }
  }
}
