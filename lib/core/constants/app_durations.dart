abstract class AppDurations {
  static const micro = Duration(milliseconds: 80);
  static const fast = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 300);
  static const rich = Duration(milliseconds: 400);
  static const spring = Duration(milliseconds: 500);
  static const shimmer = Duration(milliseconds: 1500);
  static const pageTransition = Duration(milliseconds: 320);

  /// Onboarding carousel crossfade between slides — cinematic, never abrupt.
  static const crossfade = Duration(milliseconds: 1000);

  /// Durée d'un cycle complet de rotation du KynzaLoader — calibrée pour
  /// rester fluide sans paraître mou ou nerveux. Ne pas modifier sans
  /// validation produit explicite.
  static const loaderOrbit = Duration(milliseconds: 1400);
}
