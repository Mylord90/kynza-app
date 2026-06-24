import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/currency_formatter.dart';

part 'service_model.freezed.dart';
part 'service_model.g.dart';

@freezed
class ServiceModel with _$ServiceModel {
  const factory ServiceModel({
    String? id,
    required String salonId,
    required String name,
    String? description,
    required String category,
    required int durationMin,
    @Default(0) int bufferMin,
    required int priceBif,
    String? imageUrl,
    @Default(true) bool isActive,
    @Default(0) int displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _ServiceModel;

  factory ServiceModel.fromSupabase(Map<String, dynamic> json) =>
      ServiceModel.fromJson(json);

  factory ServiceModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceModelFromJson(json);
}

extension ServiceModelX on ServiceModel {
  String get formattedPrice => CurrencyFormatter.formatBif(priceBif);

  String get formattedDuration {
    if (durationMin < 60) return '$durationMin min';
    final hours = durationMin ~/ 60;
    final minutes = durationMin % 60;
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}min';
  }
}
