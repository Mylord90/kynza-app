import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../enums/user_role.dart';
import '../providers/app_providers.dart';
import '../providers/auth_providers.dart';
import 'permission_cache.dart';

/// (feature, action, resource) tuple — resource defaults to '' to match
/// check_permission()'s NOT NULL DEFAULT '' column (a nullable resource
/// would break the cache table's UNIQUE constraint, see the migration).
typedef PermissionQuery = ({String feature, String action, String resource});

class PermissionService {
  const PermissionService(this._client);

  final SupabaseClient _client;

  String _cacheKey(String salonId, String userId, PermissionQuery query) =>
      '$salonId:$userId:${query.feature}.${query.action}.${query.resource}';

  Future<bool> hasPermission({
    required String userId,
    required String salonId,
    required PermissionQuery query,
  }) async {
    final key = _cacheKey(salonId, userId, query);
    final cached = PermissionCache.get(key);
    if (cached != null) return cached;

    try {
      final result = await _client.rpc(
        'check_permission',
        params: {
          'p_user_id': userId,
          'p_salon_id': salonId,
          'p_feature': query.feature,
          'p_action': query.action,
          'p_resource': query.resource,
        },
      );
      final hasPerm = result == true;
      await PermissionCache.set(key, hasPerm);
      return hasPerm;
    } catch (_) {
      // Fail closed — an unreachable backend must never grant access.
      return false;
    }
  }

  Future<void> invalidateCache() => PermissionCache.clear();
}

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => PermissionService(ref.watch(supabaseClientProvider)),
);

/// Resolves to `false` while there's no signed-in salon member. Owner is
/// short-circuited client-side to skip the round trip — check_permission()
/// enforces the same owner-always-allowed rule server-side regardless, so
/// this is a pure UX optimization, not a security boundary.
final permissionProvider = FutureProvider.autoDispose
    .family<bool, PermissionQuery>((ref, query) async {
      final profile = await ref.watch(currentUserProfileProvider.future);
      if (profile == null || profile.salonId == null) return false;
      if (profile.role == UserRole.owner) return true;

      final service = ref.watch(permissionServiceProvider);
      return service.hasPermission(
        userId: profile.id,
        salonId: profile.salonId!,
        query: query,
      );
    });
