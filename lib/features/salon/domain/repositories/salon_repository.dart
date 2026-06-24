import 'dart:typed_data';
import '../../../../core/models/salon_full_model.dart';
import '../../../../core/models/salon_media_model.dart';
import '../../../../core/models/working_hour_model.dart';

abstract class SalonRepository {
  Future<SalonFullModel> createSalon(SalonFullModel salon);
  Future<SalonFullModel> updateSalon(SalonFullModel salon);
  Future<SalonFullModel?> getSalon(String salonId);
  Future<SalonFullModel?> getOwnerSalon(String ownerId);
  Future<List<SalonFullModel>> getDiscoverSalons();
  Future<Set<String>> getSalonIdsByCategory(String category);
  Future<String> uploadLogo(String salonId, Uint8List bytes, String ext);
  Future<String> uploadCover(String salonId, Uint8List bytes, String ext);
  Future<SalonMediaModel> uploadMedia(
    String salonId,
    Uint8List bytes,
    String ext,
    MediaType type,
  );
  Future<void> deleteMedia(String mediaId);
  Future<void> reorderMedia(String salonId, List<String> orderedIds);
  Future<void> updateWorkingHours(String salonId, List<WorkingHourModel> hours);
}
