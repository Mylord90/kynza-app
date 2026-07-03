import '../../../../core/errors/app_exception.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/client_profile_repository.dart';

class ClientProfileRepositoryImpl implements ClientProfileRepository {
  @override
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
    String? email,
  }) async {
    try {
      await SupabaseService.from('users')
          .update({'full_name': fullName, 'phone': phone, 'email': email})
          .eq('id', userId);
    } catch (_) {
      throw const AppException('Impossible de mettre à jour votre profil.');
    }
  }
}
