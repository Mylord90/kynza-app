import '../../../../core/models/legal/data_deletion_request_model.dart';

abstract class DataDeletionRepository {
  Future<List<DataDeletionRequestModel>> getUserRequests(String userId);

  Future<DataDeletionRequestModel> createRequest({
    required String userId,
    String? notes,
  });
}
