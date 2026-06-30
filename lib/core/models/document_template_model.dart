import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_template_model.freezed.dart';
part 'document_template_model.g.dart';

@freezed
class DocumentTemplateModel with _$DocumentTemplateModel {
  const factory DocumentTemplateModel({
    required String id,
    required String salonId,
    required String type,
    required String name,
    required String body,
    @Default('fr') String language,
    @Default(false) bool isDefault,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _DocumentTemplateModel;

  factory DocumentTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$DocumentTemplateModelFromJson(json);
}