import 'package:freezed_annotation/freezed_annotation.dart';
import '../../enums/app_enums.dart';
import '../../utils/currency_formatter.dart';

part 'promotion_model.freezed.dart';
part 'promotion_model.g.dart';

class DiscountTypeConverter extends JsonConverter<DiscountType, String> {
  const DiscountTypeConverter();

  static const _toDb = {
    DiscountType.percent: 'percent',
    DiscountType.fixedBif: 'fixed_bif',
  };

  @override
  DiscountType fromJson(String json) => _toDb.entries
      .firstWhere((e) => e.value == json, orElse: () => _toDb.entries.first)
      .key;

  @override
  String toJson(DiscountType object) => _toDb[object]!;
}

@freezed
class PromotionModel with _$PromotionModel {
  const factory PromotionModel({
    String? id,
    required String salonId,
    required String title,
    String? description,
    @DiscountTypeConverter()
    @Default(DiscountType.percent)
    DiscountType discountType,
    required int discountValue,
    String? serviceId,
    @Default(0) int minBookingBif,
    int? maxUses,
    @Default(0) int currentUses,
    String? promoCode,
    required DateTime startsAt,
    required DateTime endsAt,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _PromotionModel;

  factory PromotionModel.fromSupabase(Map<String, dynamic> json) =>
      PromotionModel.fromJson(json);

  factory PromotionModel.fromJson(Map<String, dynamic> json) =>
      _$PromotionModelFromJson(json);
}

extension PromotionModelX on PromotionModel {
  String get formattedDiscount => switch (discountType) {
    DiscountType.percent => '-$discountValue%',
    DiscountType.fixedBif => '-${CurrencyFormatter.formatBif(discountValue)}',
  };

  bool get isExpired => endsAt.isBefore(DateTime.now());
  bool get isStarted => startsAt.isBefore(DateTime.now());
  bool get isLive => isActive && isStarted && !isExpired;
}
