import '../services/crash_reporting_service.dart';
import '../services/supabase_service.dart';

/// Centralized writer for the append-only `activity_logs` table. Per the
/// existing `logs_self_insert_safe` RLS policy, a direct client-side
/// insert must come from the acting user's own session, with `salon_id`
/// matching their own row in `public.users` — so [salonId] is required
/// and a signed-out caller (no `auth.uid()`) is a silent no-op rather
/// than an error. There is deliberately no salon-less call path: a
/// CLIENT-role user has `salon_id = null` and the policy would reject
/// the row outright (`NULL IN (...)` is never true), so client actions
/// without a salon are not logged here — consistent with this app's
/// strict per-salon tenant isolation, not a gap to patch around.
abstract class AuditLogger {
  /// Never throws — a failed audit write must not break the booking,
  /// payment, or settings flow that triggered it. Failures are reported
  /// through Crashlytics for visibility instead.
  static Future<void> log({
    required String salonId,
    required String typeAction,
    String? tableName,
    String? recordId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String severity = 'info',
    bool isSensitive = false,
  }) async {
    try {
      final userId = SupabaseService.auth.currentUser?.id;
      if (userId == null) return;
      await SupabaseService.from('activity_logs').insert({
        'salon_id': salonId,
        'user_id': userId,
        'type_action': typeAction,
        'table_name': tableName,
        'record_id': recordId,
        'old_values': oldValues,
        'new_values': newValues,
        'severity': severity,
        'is_sensitive': isSensitive,
      });
    } catch (e, st) {
      CrashReportingService.log('AuditLogger.log failed: $typeAction');
      CrashReportingService.recordError(e, st);
    }
  }

  static Future<void> authLogin(String salonId) =>
      log(salonId: salonId, typeAction: 'user_login');

  static Future<void> authLogout(String salonId) =>
      log(salonId: salonId, typeAction: 'user_logout');

  static Future<void> permissionGroupCreated(
    String salonId,
    String groupId,
    String groupName,
  ) => log(
    salonId: salonId,
    typeAction: 'permission_group_created',
    tableName: 'permission_groups',
    recordId: groupId,
    newValues: {'name': groupName},
    severity: 'warning',
    isSensitive: true,
  );

  static Future<void> permissionGroupDeleted(
    String salonId,
    String groupId,
    String groupName,
  ) => log(
    salonId: salonId,
    typeAction: 'permission_group_deleted',
    tableName: 'permission_groups',
    recordId: groupId,
    oldValues: {'name': groupName},
    severity: 'warning',
    isSensitive: true,
  );

  static Future<void> permissionGroupPermissionChanged(
    String salonId,
    String groupId,
    String permissionId,
    bool granted,
  ) => log(
    salonId: salonId,
    typeAction: 'permission_group_permission_changed',
    tableName: 'permission_group_permissions',
    recordId: groupId,
    newValues: {'permissionId': permissionId, 'granted': granted},
    severity: 'warning',
    isSensitive: true,
  );

  static Future<void> permissionGroupMemberAdded(
    String salonId,
    String groupId,
    String userId,
  ) => log(
    salonId: salonId,
    typeAction: 'permission_group_member_added',
    tableName: 'user_permission_groups',
    recordId: groupId,
    newValues: {'userId': userId},
    severity: 'warning',
    isSensitive: true,
  );

  static Future<void> settingsChanged(
    String salonId,
    String key,
    dynamic oldValue,
    dynamic newValue,
  ) => log(
    salonId: salonId,
    typeAction: 'settings_changed',
    tableName: 'salon_settings',
    recordId: salonId,
    oldValues: {key: oldValue},
    newValues: {key: newValue},
    severity: 'warning',
    isSensitive: true,
  );

  static Future<void> permissionGroupMemberRemoved(
    String salonId,
    String groupId,
    String userId,
  ) => log(
    salonId: salonId,
    typeAction: 'permission_group_member_removed',
    tableName: 'user_permission_groups',
    recordId: groupId,
    oldValues: {'userId': userId},
    severity: 'warning',
    isSensitive: true,
  );
}
