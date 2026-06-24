import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/models/review/review_model.dart';
import 'package:kynza/core/models/review/salon_rating_model.dart';

void main() {
  group('ReviewModelX.starDisplay', () {
    test('shows one filled star and four empty for a rating of 1', () {
      const review = ReviewModel(
        salonId: 's1',
        clientId: 'c1',
        bookingId: 'b1',
        rating: 1,
      );
      expect(review.starDisplay, '★☆☆☆☆');
    });

    test('shows five filled stars for a perfect rating', () {
      const review = ReviewModel(
        salonId: 's1',
        clientId: 'c1',
        bookingId: 'b1',
        rating: 5,
      );
      expect(review.starDisplay, '★★★★★');
    });
  });

  group('ReviewModelX.hasOwnerReply', () {
    test('false when ownerReply is null', () {
      const review = ReviewModel(
        salonId: 's1',
        clientId: 'c1',
        bookingId: 'b1',
        rating: 4,
      );
      expect(review.hasOwnerReply, isFalse);
    });

    test('false when ownerReply is an empty string', () {
      const review = ReviewModel(
        salonId: 's1',
        clientId: 'c1',
        bookingId: 'b1',
        rating: 4,
        ownerReply: '',
      );
      expect(review.hasOwnerReply, isFalse);
    });

    test('true once the owner has actually replied', () {
      const review = ReviewModel(
        salonId: 's1',
        clientId: 'c1',
        bookingId: 'b1',
        rating: 4,
        ownerReply: 'Merci pour votre visite !',
      );
      expect(review.hasOwnerReply, isTrue);
    });
  });

  group('SalonRatingModel.empty', () {
    test('produces a zeroed-out rating for a salon with no reviews', () {
      final rating = SalonRatingModel.empty('s1');
      expect(rating.totalReviews, 0);
      expect(rating.averageRating, 0.0);
      expect(rating.distribution, [0, 0, 0, 0, 0]);
    });
  });

  group('SalonRatingModelX.distribution', () {
    test('returns all zeros when there are no reviews yet', () {
      const rating = SalonRatingModel(salonId: 's1');
      expect(rating.distribution, [0, 0, 0, 0, 0]);
    });

    test('computes the percentage of each star bucket, 5★ down to 1★', () {
      const rating = SalonRatingModel(
        salonId: 's1',
        totalReviews: 10,
        fiveStar: 5,
        fourStar: 3,
        threeStar: 1,
        twoStar: 1,
        oneStar: 0,
      );
      expect(rating.distribution, [50.0, 30.0, 10.0, 10.0, 0.0]);
    });
  });
}
