import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_model.freezed.dart';
part 'review_model.g.dart';

@freezed
class ReviewModel with _$ReviewModel {
  const factory ReviewModel({
    String? id,
    required String salonId,
    required String clientId,
    required String bookingId,
    required int rating,
    String? comment,
    @Default(false) bool isAnonymous,
    @Default(true) bool isVerified,
    String? ownerReply,
    DateTime? ownerRepliedAt,
    @Default(false) bool isFlagged,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _ReviewModel;

  factory ReviewModel.fromSupabase(Map<String, dynamic> json) =>
      ReviewModel.fromJson(json);

  factory ReviewModel.fromJson(Map<String, dynamic> json) =>
      _$ReviewModelFromJson(json);
}

extension ReviewModelX on ReviewModel {
  String get starDisplay => '★' * rating + '☆' * (5 - rating);
  bool get hasOwnerReply => ownerReply != null && ownerReply!.isNotEmpty;
}
