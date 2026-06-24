import '../../../../core/models/service_model.dart';

abstract class ServiceRepository {
  Future<List<ServiceModel>> getAll(String salonId);
  Future<ServiceModel> create(ServiceModel service);
  Future<ServiceModel> update(ServiceModel service);
  Future<void> softDelete(String id);
  Future<void> toggleActive(String id, bool isActive);
  Future<void> reorder(String salonId, List<String> orderedIds);
}
