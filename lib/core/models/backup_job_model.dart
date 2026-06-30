import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_job_model.freezed.dart';
part 'backup_job_model.g.dart';

@freezed
class BackupJobModel with _$BackupJobModel {
  const factory BackupJobModel({
    required String id,
    required String salonId,
    required String initiatedBy,
    required String status,
    String? storagePath,
    int? fileSizeBytes,
    String? errorMessage,
    @Default([]) List<String> tablesIncluded,
    int? recordsExported,
    required DateTime createdAt,
    DateTime? completedAt,
  }) = _BackupJobModel;

  factory BackupJobModel.fromJson(Map<String, dynamic> json) =>
      _$BackupJobModelFromJson(json);
}