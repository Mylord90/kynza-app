import '../../../../core/models/review/review_model.dart';
import '../../../../core/models/review/salon_rating_model.dart';

abstract class ReviewRepository {
  Future<ReviewModel> createReview(ReviewModel review);
  Future<ReviewModel> updateReview(String id, int rating, String? comment);
  Future<ReviewModel> replyToReview(String id, String reply);
  Future<List<ReviewModel>> getSalonReviews(String salonId, {int page = 0});
  Future<SalonRatingModel> getSalonRating(String salonId);
  Future<bool> canReview(String bookingId);
  Future<void> flagReview(String id);
}
