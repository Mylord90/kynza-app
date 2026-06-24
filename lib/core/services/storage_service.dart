import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../errors/app_exception.dart';
import 'supabase_service.dart';

/// Wraps the `kynza-media` Supabase Storage bucket.
/// Path convention: salon/{salonId}/{type}/{uuid}.{ext} — the {salonId}
/// segment is what storage RLS checks against has_role(owner|manager).
abstract class StorageService {
  static const _bucket = 'kynza-media';
  static const _uuid = Uuid();

  static Future<String> uploadSalonLogo(
    String salonId,
    Uint8List bytes,
    String ext,
  ) => _upload(salonId, 'logo', bytes, ext);

  static Future<String> uploadSalonCover(
    String salonId,
    Uint8List bytes,
    String ext,
  ) => _upload(salonId, 'cover', bytes, ext);

  static Future<String> uploadPortfolioImage(
    String salonId,
    Uint8List bytes,
    String ext,
  ) => _upload(salonId, 'portfolio', bytes, ext);

  static Future<String> uploadPortfolioVideo(
    String salonId,
    Uint8List bytes,
    String ext,
  ) => _upload(salonId, 'portfolio', bytes, ext);

  static Future<String> uploadUserAvatar(
    String userId,
    Uint8List bytes,
    String ext,
  ) async {
    try {
      final path = 'user/$userId/avatar/${_uuid.v4()}.$ext';
      await SupabaseService.client.storage
          .from(_bucket)
          .uploadBinary(path, bytes);
      return SupabaseService.client.storage.from(_bucket).getPublicUrl(path);
    } catch (_) {
      throw const AppException("Échec de l'envoi de la photo. Réessayez.");
    }
  }

  static Future<void> deleteMedia(String path) async {
    try {
      await SupabaseService.client.storage.from(_bucket).remove([path]);
    } catch (_) {
      throw const AppException('Impossible de supprimer ce média.');
    }
  }

  static Future<String> _upload(
    String salonId,
    String type,
    Uint8List bytes,
    String ext,
  ) async {
    try {
      final path = 'salon/$salonId/$type/${_uuid.v4()}.$ext';
      await SupabaseService.client.storage
          .from(_bucket)
          .uploadBinary(path, bytes);
      return SupabaseService.client.storage.from(_bucket).getPublicUrl(path);
    } catch (_) {
      throw const AppException("Échec de l'envoi du média. Réessayez.");
    }
  }
}
