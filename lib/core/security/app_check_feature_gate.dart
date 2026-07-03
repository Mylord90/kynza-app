import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/evolution/feature_flags/application/providers/feature_flag_providers.dart';
import '../constants/env.dart';

/// The double gate App Check activation checks before doing anything: the
/// `feature_app_check` flag (evaluated server-side, same mechanism as every
/// other feature flag) **and** `Env.appCheckEnabled` actually being set at
/// build time. Both must hold — mirrors the exact shape of
/// `GoogleMapsFeatureGate` (Phase 7) for the same reason: a flag flipped on
/// by mistake in the admin screen still can't activate anything without an
/// explicit build-time opt-in too, and vice versa. See
/// docs/security/APP_CHECK_ARCHITECTURE.md.
abstract class AppCheckFeatureGate {
  /// No network call — short-circuits `appCheckEnabledProvider` before it
  /// ever reaches Supabase, exactly like `GoogleMapsFeatureGate.hasApiKey`.
  static bool get isOptedIn => Env.appCheckEnabled;
}

/// `false` today, always — `Env.appCheckEnabled` defaults to false (no
/// `--dart-define=APP_CHECK_ENABLED=true` build), which short-circuits
/// before the flag RPC is even called. Proven by test
/// (`test/unit/app_check_feature_gate_test.dart`) without touching Supabase.
final appCheckEnabledProvider = FutureProvider<bool>((ref) async {
  if (!AppCheckFeatureGate.isOptedIn) return false;
  return ref.watch(featureFlagEvaluationProvider('feature_app_check').future);
});
