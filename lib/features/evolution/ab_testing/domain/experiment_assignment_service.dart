/// Deterministic, offline-capable variant assignment — no server round trip
/// needed to know which variant a user is in, mirroring the same
/// hash-and-bucket approach `evaluate_feature_flag()` uses server-side
/// (Phase 3), reimplemented here in pure Dart since assignment must work
/// without a network call. A given (userId, experimentKey) pair always maps
/// to the same variant, on any device, on any run — this is precisely
/// Phase 7's "deterministic and offline-capable" exit criterion.
abstract class ExperimentAssignmentService {
  /// [variantWeights] maps variant name → integer weight (weights need not
  /// sum to 100; buckets are proportional). Returns the assigned variant
  /// name, or null if [variantWeights] is empty.
  static String? assign({
    required String userId,
    required String experimentKey,
    required Map<String, int> variantWeights,
  }) {
    if (variantWeights.isEmpty) return null;
    final totalWeight = variantWeights.values.fold<int>(0, (a, b) => a + b);
    if (totalWeight <= 0) return null;

    final bucket = _stableHash('$userId:$experimentKey') % totalWeight;

    var cumulative = 0;
    for (final entry in variantWeights.entries) {
      cumulative += entry.value;
      if (bucket < cumulative) return entry.key;
    }
    return variantWeights.keys.last;
  }

  /// FNV-1a 32-bit — deterministic, stable across platforms/runs, no
  /// external dependency needed (this codebase avoids adding a `crypto`
  /// dependency for a use case that doesn't need cryptographic strength,
  /// only stable bucketing).
  static int _stableHash(String input) {
    var hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}
