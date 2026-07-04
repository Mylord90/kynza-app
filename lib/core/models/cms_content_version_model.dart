import 'package:freezed_annotation/freezed_annotation.dart';

part 'cms_content_version_model.freezed.dart';
part 'cms_content_version_model.g.dart';

@freezed
class CmsContentVersionModel with _$CmsContentVersionModel {
  const factory CmsContentVersionModel({
    required String id,
    required String contentId,
    required int versionNumber,
    required String bodyMarkdown,
    String? changedBy,
    required DateTime changedAt,
  }) = _CmsContentVersionModel;

  factory CmsContentVersionModel.fromJson(Map<String, dynamic> json) =>
      _$CmsContentVersionModelFromJson(json);
}
