import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_plan_model.freezed.dart';
part 'subscription_plan_model.g.dart';

@freezed
class SubscriptionPlanModel with _$SubscriptionPlanModel {
  const factory SubscriptionPlanModel({
    String? id,
    required String key,
    required String name,
    required String tagline,
    @Default(0) int priceBif,
    required String period,
    @Default(<String>[]) List<String> features,
    @Default(false) bool isFeatured,
  }) = _SubscriptionPlanModel;

  factory SubscriptionPlanModel.fromSupabase(Map<String, dynamic> json) =>
      SubscriptionPlanModel.fromJson(json);

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanModelFromJson(json);
}

extension SubscriptionPlanModelX on SubscriptionPlanModel {
  String get periodLabel => switch (period) {
    'lifetime' => 'à vie',
    'month' => '/ mois',
    'year' => '/ an',
    _ => '',
  };
}
