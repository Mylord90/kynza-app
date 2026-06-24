import 'package:freezed_annotation/freezed_annotation.dart';

part 'salon_rating_model.freezed.dart';
part 'salon_rating_model.g.dart';

/// One row of `public.v_salon_ratings` — the rating rollup for a salon.
@freezed
class SalonRatingModel with _$SalonRatingModel {
  const factory SalonRatingModel({
    required String salonId,
    @Default(0) int totalReviews,
    @Default(0.0) double averageRating,
    @Default(0) int fiveStar,
    @Default(0) int fourStar,
    @Default(0) int threeStar,
    @Default(0) int twoStar,
    @Default(0) int oneStar,
  }) = _SalonRatingModel;

  factory SalonRatingModel.empty(String salonId) =>
      SalonRatingModel(salonId: salonId);

  factory SalonRatingModel.fromSupabase(Map<String, dynamic> json) =>
      SalonRatingModel.fromJson(json);

  factory SalonRatingModel.fromJson(Map<String, dynamic> json) =>
      _$SalonRatingModelFromJson(json);
}

extension SalonRatingModelX on SalonRatingModel {
  /// Percentage (0–100) of [totalReviews] for each star, 5★ down to 1★.
  List<double> get distribution {
    if (totalReviews == 0) return const [0, 0, 0, 0, 0];
    return [
      fiveStar,
      fourStar,
      threeStar,
      twoStar,
      oneStar,
    ].map((count) => count * 100 / totalReviews).toList();
  }
}
