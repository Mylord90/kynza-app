import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/errors/app_exception.dart';
import 'package:kynza/features/proxipay/data/repositories/proxipay_repository_impl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockFunctionsClient extends Mock implements FunctionsClient {}

/// P2-10 (Master Inventory: zero repository-layer test files exist, no
/// DI/mocking seam) — `ProxiPayRepositoryImpl` now takes an injectable
/// `SupabaseClient`, established here as the first real repository-layer
/// test in this codebase using that seam. Scoped to `createSession`'s
/// failure path (driven entirely by `client.functions.invoke`, no
/// `.from()` fluent-builder chain to fake) — a deliberately bounded proof
/// of the pattern, not a full rewrite of all 20+ zero-coverage
/// repositories in one pass.
///
/// `confirmSession` could NOT be covered here: it wraps its body in
/// `PerformanceMonitoringService.traceAsync`, which calls
/// `FirebasePerformance.instance` before the wrapped callback ever runs —
/// throwing `[core/no-app] No Firebase App has been created` in a plain
/// unit test, outside `confirmSession`'s own try/catch entirely. Testing
/// it would need Firebase platform-channel mocking
/// (`setupFirebaseCoreMocks`-style boilerplate) that doesn't exist
/// anywhere in this test suite yet — a real, separate gap, not silently
/// worked around here.
void main() {
  late _MockSupabaseClient client;
  late _MockFunctionsClient functions;
  late ProxiPayRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    client = _MockSupabaseClient();
    functions = _MockFunctionsClient();
    when(() => client.functions).thenReturn(functions);
    repo = ProxiPayRepositoryImpl(client: client);
  });

  group('createSession', () {
    test(
      'throws session_create_failed when the Edge Function returns a non-200 status',
      () async {
        when(
          () => functions.invoke(
            'proxipay-create-session',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 500, data: {'error': 'boom'}),
        );

        await expectLater(
          repo.createSession('booking-1'),
          throwsA(
            isA<AppException>().having(
              (e) => e.message,
              'message',
              'session_create_failed',
            ),
          ),
        );
      },
    );

    test(
      'wraps an unexpected network failure in a generic AppException',
      () async {
        when(
          () => functions.invoke(
            'proxipay-create-session',
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('network down'));

        await expectLater(
          repo.createSession('booking-1'),
          throwsA(isA<AppException>()),
        );
      },
    );
  });
}
