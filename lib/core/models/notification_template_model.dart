import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_template_model.freezed.dart';
part 'notification_template_model.g.dart';

@freezed
class NotificationTemplateModel with _$NotificationTemplateModel {
  const factory NotificationTemplateModel({
    String? id,
    required String eventType,
    required String titleFr,
    required String bodyFr,
    @Default(<String>['push']) List<String> channels,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _NotificationTemplateModel;

  factory NotificationTemplateModel.fromSupabase(Map<String, dynamic> json) =>
      NotificationTemplateModel.fromJson(json);

  factory NotificationTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationTemplateModelFromJson(json);
}

extension NotificationTemplateModelX on NotificationTemplateModel {
  /// Replaces every `{{key}}` placeholder in [titleFr]/[bodyFr] with the
  /// matching value from [vars]. Unmatched placeholders are left as-is
  /// rather than silently turned into empty strings — a missing variable
  /// is a caller bug that should stay visible, not be swallowed.
  (String title, String body) interpolate(Map<String, String> vars) {
    var title = titleFr;
    var body = bodyFr;
    for (final entry in vars.entries) {
      title = title.replaceAll('{{${entry.key}}}', entry.value);
      body = body.replaceAll('{{${entry.key}}}', entry.value);
    }
    return (title, body);
  }
}
