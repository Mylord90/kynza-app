import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// This is a STATIC check of the migration SQL text, not a live database
/// test — the migration is a draft, not applied to the remote project
/// (Rule 8 of the Enterprise Hardening pass), and this environment has no
/// local Postgres/Docker stack to run pgTAP against (see
/// docs/audit/PHASE_0_BASELINE.md §7). It guards against a future edit
/// accidentally weakening the own-row RLS predicate on
/// `user_legal_acceptances`, but it does NOT prove runtime RLS enforcement.
/// A live proof (attempt to read another user's acceptance row and confirm
/// PostgREST returns zero rows) requires applying this migration to a real
/// or staging Supabase project first — out of scope for this phase.
void main() {
  late String migrationSql;

  setUpAll(() {
    migrationSql = File(
      'supabase/migrations/20260703150000_legal_center.sql',
    ).readAsStringSync();
  });

  test(
    'user_legal_acceptances SELECT policy is scoped to the row owner only',
    () {
      final selectPolicy = RegExp(
        r'CREATE POLICY "user_legal_acceptances_own_select"[\s\S]*?USING \(user_id = auth\.uid\(\)\)',
      );
      expect(
        selectPolicy.hasMatch(migrationSql),
        isTrue,
        reason:
            'Expected a SELECT policy on user_legal_acceptances gated by '
            'user_id = auth.uid() — a user must never be able to read '
            "another user's acceptance row.",
      );
    },
  );

  test(
    'user_legal_acceptances INSERT policy only allows writing your own row',
    () {
      final insertPolicy = RegExp(
        r'CREATE POLICY "user_legal_acceptances_own_insert"[\s\S]*?WITH CHECK \(user_id = auth\.uid\(\)\)',
      );
      expect(insertPolicy.hasMatch(migrationSql), isTrue);
    },
  );

  test(
    'user_legal_acceptances has no UPDATE or DELETE policy (append-only ledger)',
    () {
      expect(
        migrationSql.contains(
          'ON public.user_legal_acceptances\n  FOR UPDATE',
        ),
        isFalse,
      );
      expect(
        migrationSql.contains(
          'ON public.user_legal_acceptances\n  FOR DELETE',
        ),
        isFalse,
      );
    },
  );

  test('every new table in this migration enables row level security', () {
    const tables = [
      'legal_documents',
      'legal_document_versions',
      'user_legal_acceptances',
      'legal_consent_settings',
      'data_deletion_requests',
    ];
    for (final table in tables) {
      expect(
        migrationSql.contains(
          'ALTER TABLE public.$table ENABLE ROW LEVEL SECURITY;',
        ),
        isTrue,
        reason: '$table is missing ENABLE ROW LEVEL SECURITY',
      );
    }
  });
}
