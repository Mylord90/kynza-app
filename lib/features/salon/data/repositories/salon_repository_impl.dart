import 'dart:typed_data';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/salon_full_model.dart';
import '../../../../core/models/salon_media_model.dart';
import '../../../../core/models/working_hour_model.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/salon_repository.dart';

class SalonRepositoryImpl implements SalonRepository {
  static const _salonsTable = 'salons';
  static const _mediaTable = 'salon_media';
  static const _hoursTable = 'working_hours';

  @override
  Future<SalonFullModel> createSalon(SalonFullModel salon) async {
    try {
      final currentUserId = SupabaseService.auth.currentUser?.id;
      if (currentUserId == null) {
        throw const AppException('Session expirée. Reconnectez-vous.');
      }

      final row = await SupabaseService.from(_salonsTable)
          .insert({
            'name': salon.name,
            'owner_id': currentUserId,
            'slogan': salon.slogan,
            'description': salon.description,
            'phone': salon.phone,
            'email': salon.email,
            'address': salon.address,
            'province': salon.province,
            'commune': salon.commune,
            'latitude': salon.latitude,
            'longitude': salon.longitude,
            'logo_url': salon.logoUrl,
            'cover_url': salon.coverUrl,
            'social_facebook': salon.socialFacebook,
            'social_instagram': salon.socialInstagram,
            'social_tiktok': salon.socialTiktok,
            'social_whatsapp': salon.socialWhatsapp,
          })
          .select()
          .single();

      final created = SalonFullModel.fromSupabase(row);

      // Attach the new owner to the salon they just created — allowed
      // exactly once by the protect_user_columns() onboarding exception
      // (migration 20260623200000_salon_full_schema.sql).
      await SupabaseService.from(
        'users',
      ).update({'salon_id': created.id}).eq('id', currentUserId);
      await SupabaseService.auth.refreshSession();

      return created;
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AppException('Impossible de créer le salon. Réessayez.');
    }
  }

  @override
  Future<SalonFullModel> updateSalon(SalonFullModel salon) async {
    try {
      final row = await SupabaseService.from(_salonsTable)
          .update({
            'name': salon.name,
            'slogan': salon.slogan,
            'description': salon.description,
            'phone': salon.phone,
            'email': salon.email,
            'address': salon.address,
            'province': salon.province,
            'commune': salon.commune,
            'latitude': salon.latitude,
            'longitude': salon.longitude,
            'logo_url': salon.logoUrl,
            'cover_url': salon.coverUrl,
            'social_facebook': salon.socialFacebook,
            'social_instagram': salon.socialInstagram,
            'social_tiktok': salon.socialTiktok,
            'social_whatsapp': salon.socialWhatsapp,
          })
          .eq('id', salon.id)
          .select()
          .single();
      return SalonFullModel.fromSupabase(row);
    } catch (_) {
      throw const AppException(
        'Impossible de mettre à jour le salon. Réessayez.',
      );
    }
  }

  @override
  Future<SalonFullModel?> getSalon(String salonId) async {
    final row = await SupabaseService.from(
      _salonsTable,
    ).select().eq('id', salonId).isFilter('deleted_at', null).maybeSingle();
    if (row == null) return null;
    return _withRelations(SalonFullModel.fromSupabase(row));
  }

  @override
  Future<SalonFullModel?> getOwnerSalon(String ownerId) async {
    final row = await SupabaseService.from(_salonsTable)
        .select()
        .eq('owner_id', ownerId)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (row == null) return null;
    return _withRelations(SalonFullModel.fromSupabase(row));
  }

  @override
  Future<List<SalonFullModel>> getDiscoverSalons() async {
    final rows = await SupabaseService.from(
      _salonsTable,
    ).select().eq('is_online', true).isFilter('deleted_at', null).order('name');
    return rows.map(SalonFullModel.fromSupabase).toList();
  }

  @override
  Future<Set<String>> getSalonIdsByCategory(String category) async {
    final rows = await SupabaseService.from('services')
        .select('salon_id')
        .eq('category', category)
        .eq('is_active', true)
        .isFilter('deleted_at', null);
    return rows.map((r) => r['salon_id'] as String).toSet();
  }

  Future<SalonFullModel> _withRelations(SalonFullModel salon) async {
    final hoursRows = await SupabaseService.from(_hoursTable)
        .select()
        .eq('salon_id', salon.id)
        .isFilter('deleted_at', null)
        .order('day_of_week');
    final mediaRows = await SupabaseService.from(_mediaTable)
        .select()
        .eq('salon_id', salon.id)
        .isFilter('deleted_at', null)
        .order('display_order');
    return salon.copyWith(
      workingHours: hoursRows.map(WorkingHourModel.fromSupabase).toList(),
      media: mediaRows.map(SalonMediaModel.fromSupabase).toList(),
    );
  }

  @override
  Future<String> uploadLogo(String salonId, Uint8List bytes, String ext) =>
      StorageService.uploadSalonLogo(salonId, bytes, ext);

  @override
  Future<String> uploadCover(String salonId, Uint8List bytes, String ext) =>
      StorageService.uploadSalonCover(salonId, bytes, ext);

  @override
  Future<SalonMediaModel> uploadMedia(
    String salonId,
    Uint8List bytes,
    String ext,
    MediaType type,
  ) async {
    final url = type == MediaType.video
        ? await StorageService.uploadPortfolioVideo(salonId, bytes, ext)
        : await StorageService.uploadPortfolioImage(salonId, bytes, ext);

    try {
      final existing = await SupabaseService.from(_mediaTable)
          .select('display_order')
          .eq('salon_id', salonId)
          .isFilter('deleted_at', null)
          .order('display_order', ascending: false)
          .limit(1)
          .maybeSingle();
      final nextOrder = ((existing?['display_order'] as int?) ?? -1) + 1;

      final row = await SupabaseService.from(_mediaTable)
          .insert({
            'salon_id': salonId,
            'url': url,
            'type': type.name,
            'display_order': nextOrder,
          })
          .select()
          .single();
      return SalonMediaModel.fromSupabase(row);
    } catch (_) {
      throw const AppException("Échec de l'enregistrement du média.");
    }
  }

  @override
  Future<void> deleteMedia(String mediaId) async {
    try {
      await SupabaseService.from(_mediaTable)
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', mediaId);
    } catch (_) {
      throw const AppException('Impossible de supprimer ce média.');
    }
  }

  @override
  Future<void> reorderMedia(String salonId, List<String> orderedIds) async {
    try {
      for (var i = 0; i < orderedIds.length; i++) {
        await SupabaseService.from(_mediaTable)
            .update({'display_order': i})
            .eq('id', orderedIds[i])
            .eq('salon_id', salonId);
      }
    } catch (_) {
      throw const AppException('Impossible de réorganiser la galerie.');
    }
  }

  @override
  Future<void> updateWorkingHours(
    String salonId,
    List<WorkingHourModel> hours,
  ) async {
    try {
      for (final h in hours) {
        await SupabaseService.from(_hoursTable).upsert({
          'salon_id': salonId,
          'day_of_week': h.dayOfWeek,
          'opens_at': h.opensAt,
          'closes_at': h.closesAt,
          'is_closed': h.isClosed,
        }, onConflict: 'salon_id,day_of_week');
      }
    } catch (_) {
      throw const AppException(
        "Impossible d'enregistrer les horaires. Réessayez.",
      );
    }
  }
}
