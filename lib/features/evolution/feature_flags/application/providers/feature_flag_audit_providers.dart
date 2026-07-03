import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/services/supabase_service.dart';

/// A single flag-override audit entry, read from the existing `activity_logs`
/// table (Phase 10 of this pass extends this into the full cross-domain
/// audit engine — this is a narrow, flag-scoped read, not a second pipeline).
class FeatureFlagAuditEntry {
  const FeatureFlagAuditEntry({
    required this.typeAction,
    required this.flagKey,
    required this.scope,
    required this.target,
    required this.createdAt,
  });

  final String typeAction;
  final String? flagKey;
  final String? scope;
  final String? target;
  final DateTime createdAt;

  factory FeatureFlagAuditEntry.fromRow(Map<String, dynamic> row) {
    final values = (row['new_values'] as Map<String, dynamic>?) ??
        (row['old_values'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    return FeatureFlagAuditEntry(
      typeAction: row['type_action'] as String,
      flagKey: row['record_id'] as String?,
      scope: values['scope'] as String?,
      target: values['target'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

final featureFlagAuditLogProvider =
    FutureProvider.family<List<FeatureFlagAuditEntry>, String>((
      ref,
      salonId,
    ) async {
      final rows = await SupabaseService.from('activity_logs')
          .select()
          .eq('salon_id', salonId)
          .inFilter('type_action', [
            'feature_flag_override_set',
            'feature_flag_override_removed',
          ])
          .order('created_at', ascending: false)
          .limit(100);
      return rows.map(FeatureFlagAuditEntry.fromRow).toList();
    });
