import 'package:freezed_annotation/freezed_annotation.dart';
import '../../enums/app_enums.dart';

part 'data_deletion_request_model.freezed.dart';
part 'data_deletion_request_model.g.dart';

class DataDeletionStatusConverter extends JsonConverter<DataDeletionStatus, String> {
  const DataDeletionStatusConverter();

  static const _toDb = {
    DataDeletionStatus.pending: 'pending',
    DataDeletionStatus.inReview: 'in_review',
    DataDeletionStatus.completed: 'completed',
    DataDeletionStatus.rejected: 'rejected',
  };

  @override
  DataDeletionStatus fromJson(String json) => _toDb.entries
      .firstWhere((e) => e.value == json, orElse: () => _toDb.entries.first)
      .key;

  @override
  String toJson(DataDeletionStatus object) => _toDb[object]!;
}

@freezed
class DataDeletionRequestModel with _$DataDeletionRequestModel {
  const factory DataDeletionRequestModel({
    String? id,
    required String userId,
    DateTime? requestedAt,
    @DataDeletionStatusConverter()
    @Default(DataDeletionStatus.pending)
    DataDeletionStatus status,
    DateTime? processedAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _DataDeletionRequestModel;

  factory DataDeletionRequestModel.fromSupabase(Map<String, dynamic> json) =>
      DataDeletionRequestModel.fromJson(json);

  factory DataDeletionRequestModel.fromJson(Map<String, dynamic> json) =>
      _$DataDeletionRequestModelFromJson(json);
}
