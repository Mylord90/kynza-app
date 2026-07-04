import 'package:freezed_annotation/freezed_annotation.dart';

part 'cms_content_model.freezed.dart';
part 'cms_content_model.g.dart';

@freezed
class CmsContentModel with _$CmsContentModel {
  const factory CmsContentModel({
    required String id,
    required String type,
    required String slug,
    @Default('fr') String locale,
    required String title,
    required String bodyMarkdown,
    @Default('draft') String status,
    DateTime? publishedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CmsContentModel;

  factory CmsContentModel.fromJson(Map<String, dynamic> json) =>
      _$CmsContentModelFromJson(json);
}

extension CmsContentModelX on CmsContentModel {
  bool get isPublished => status == 'published';
}
