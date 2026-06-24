import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/review/review_model.dart';
import '../../../../core/models/review/salon_rating_model.dart';
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

  Future<void> createReview(ReviewModel review) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(reviewRepositoryProvider).createReview(review),
    );
    ref.invalidate(salonReviewsProvider(review.salonId));
    ref.invalidate(salonRatingProvider(review.salonId));
    ref.invalidate(canReviewProvider(review.bookingId));
  }

  Future<void> updateReview(
    String salonId,
    String id,
    int rating,
    String? comment,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () =>
          ref.read(reviewRepositoryProvider).updateReview(id, rating, comment),
    );
    ref.invalidate(salonReviewsProvider(salonId));
    ref.invalidate(salonRatingProvider(salonId));
  }

  Future<void> replyToReview(String salonId, String id, String reply) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(reviewRepositoryProvider).replyToReview(id, reply),
    );
    ref.invalidate(salonReviewsProvider(salonId));
  }

  Future<void> flagReview(String salonId, String id) async {
    state = await AsyncValue.guard(
      () => ref.read(reviewRepositoryProvider).flagReview(id),
    );
    ref.invalidate(salonReviewsProvider(salonId));
  }
}
