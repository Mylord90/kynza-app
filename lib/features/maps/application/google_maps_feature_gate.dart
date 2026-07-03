import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/env.dart';
import '../../evolution/feature_flags/application/providers/feature_flag_providers.dart';

/// The double gate every Google Maps repository checks before doing
/// anything: the `feature_google_maps` flag (evaluated server-side, same
/// as every other feature flag) **and** a real API key actually being
/// configured. Both must hold — a flag flipped on by mistake in the admin
/// screen still can't activate anything without a key also being supplied
/// at build time, and vice versa. See docs/GOOGLE_MAPS_ARCHITECTURE.md.
abstract class GoogleMapsFeatureGate {
  /// No network call — a real key is required before the flag is even
  /// worth checking, so this short-circuits `googleMapsEnabledProvider`
  /// before it ever reaches Supabase.
  static bool get hasApiKey => Env.googleMapsApiKey.isNotEmpty;
}

/// `false` today, always — `hasApiKey` is false (no key configured), which
/// short-circuits before the flag RPC is even called. Proven by test
/// (`test/unit/google_maps_feature_gate_test.dart`) without touching
/// Supabase.
final googleMapsEnabledProvider = FutureProvider<bool>((ref) async {
  if (!GoogleMapsFeatureGate.hasApiKey) return false;
  return ref.watch(featureFlagEvaluationProvider('feature_google_maps').future);
});
