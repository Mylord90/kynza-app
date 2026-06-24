import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/supabase_service.dart';

final clientProfileNotifierProvider =
    AsyncNotifierProvider<ClientProfileNotifier, void>(
      ClientProfileNotifier.new,
    );

class ClientProfileNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? email,
  }) async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await SupabaseService.from('users')
            .update({'full_name': fullName, 'phone': phone, 'email': email})
            .eq('id', userId);
      } catch (_) {
        throw const AppException('Impossible de mettre à jour votre profil.');
      }
    });
    ref.invalidate(currentUserProfileProvider);
  }

  Future<void> uploadAvatar(Uint8List bytes, String ext) async {
    final userId = SupabaseService.auth.currentUser?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final url = await StorageService.uploadUserAvatar(userId, bytes, ext);
      await SupabaseService.from(
        'users',
      ).update({'avatar_url': url}).eq('id', userId);
    });
    ref.invalidate(currentUserProfileProvider);
  }
}
