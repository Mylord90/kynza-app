import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/review/review_model.dart';
import '../../../../core/models/review/salon_rating_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/review_repository.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  static const _table = 'reviews';
  static const _pageSize = 10;

  @override
  Future<ReviewModel> createReview(ReviewModel review) async {
    try {
      final row = await SupabaseService.from(_table)
          .insert({
            'salon_id': review.salonId,
            'client_id': review.clientId,
            'booking_id': review.bookingId,
            'rating': review.rating,
            'comment': review.comment,
            'is_anonymous': review.isAnonymous,
          })
          .select()
          .single();
      return ReviewModel.fromSupabase(row);
    } catch (_) {
      throw const AppException("Impossible de publier votre avis.");
    }
  }

  @override
  Future<ReviewModel> updateReview(
    String id,
    int rating,
    String? comment,
  ) async {
    try {
      final row = await SupabaseService.from(_table)
          .update({'rating': rating, 'comment': comment})
          .eq('id', id)
          .select()
          .single();
      return ReviewModel.fromSupabase(row);
    } catch (_) {
      throw const AppException(
        "Impossible de modifier cet avis (délai de 30 jours dépassé ou réponse déjà publiée).",
      );
    }
  }

  @override
  Future<ReviewModel> replyToReview(String id, String reply) async {
    try {
      final row = await SupabaseService.from(_table)
          .update({
            'owner_reply': reply,
            'owner_replied_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();
      return ReviewModel.fromSupabase(row);
    } catch (_) {
      throw const AppException('Impossible de publier votre réponse.');
    }
  }

  @override
  Future<List<ReviewModel>> getSalonReviews(
    String salonId, {
    int page = 0,
  }) async {
    final from = page * _pageSize;
    final rows = await SupabaseService.from(_table)
        .select()
        .eq('salon_id', salonId)
        .isFilter('deleted_at', null)
        .eq('is_flagged', false)
        .order('created_at', ascending: false)
        .range(from, from + _pageSize - 1);
    return rows.map(ReviewModel.fromSupabase).toList();
  }

  @override
  Future<SalonRatingModel> getSalonRating(String salonId) async {
    final row = await SupabaseService.from(
      'v_salon_ratings',
    ).select().eq('salon_id', salonId).maybeSingle();
    return row == null
        ? SalonRatingModel.empty(salonId)
        : SalonRatingModel.fromSupabase(row);
  }

  @override
  Future<bool> canReview(String bookingId) async {
    final uid = SupabaseService.auth.currentUser?.id;
    if (uid == null) return false;

    final booking = await SupabaseService.from(
      'bookings',
    ).select('client_id, status').eq('id', bookingId).maybeSingle();
    if (booking == null ||
        booking['client_id'] != uid ||
        booking['status'] != 'completed') {
      return false;
    }

    final existing = await SupabaseService.from(
      _table,
    ).select('id').eq('booking_id', bookingId).maybeSingle();
    return existing == null;
  }

  @override
  Future<void> flagReview(String id) async {
    try {
      await SupabaseService.from(
        _table,
      ).update({'is_flagged': true}).eq('id', id);
    } catch (_) {
      throw const AppException('Impossible de signaler cet avis.');
    }
  }
}
