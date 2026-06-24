import 'package:freezed_annotation/freezed_annotation.dart';

part 'salon_media_model.freezed.dart';
part 'salon_media_model.g.dart';

enum MediaType { image, video }

class MediaTypeConverter extends JsonConverter<MediaType, String> {
  const MediaTypeConverter();

  @override
  MediaType fromJson(String json) => MediaType.values.firstWhere(
    (t) => t.name == json,
    orElse: () => MediaType.image,
  );

  @override
  String toJson(MediaType object) => object.name;
}

@freezed
class SalonMediaModel with _$SalonMediaModel {
  const factory SalonMediaModel({
    String? id,
    required String salonId,
    required String url,
    @MediaTypeConverter() @Default(MediaType.image) MediaType type,
    String? thumbnailUrl,
    String? caption,
    @Default(0) int displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _SalonMediaModel;

  factory SalonMediaModel.fromSupabase(Map<String, dynamic> json) =>
      SalonMediaModel.fromJson(json);

  factory SalonMediaModel.fromJson(Map<String, dynamic> json) =>
      _$SalonMediaModelFromJson(json);
}
