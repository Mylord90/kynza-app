import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Flips to true once all 4 onboarding carousel images (full + LQIP) have
/// been decoded into Flutter's image cache — the carousel reads this before
/// starting its crossfade/Ken Burns loop so nothing paints an empty frame.
final onboardingImagesReadyProvider = StateProvider<bool>((ref) => false);
