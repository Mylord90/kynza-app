/// Tailles standardisées du `KynzaLoader`, alignées sur les usages réels de
/// l'app — voir `docs/LOADER_GUIDE.md` pour le mapping contexte → taille.
enum KynzaLoaderSize {
  small(diameter: 16, particleCount: 5, strokeRatio: 0.12),
  medium(diameter: 28, particleCount: 6, strokeRatio: 0.14),
  large(diameter: 48, particleCount: 7, strokeRatio: 0.16),
  fullscreen(diameter: 64, particleCount: 7, strokeRatio: 0.16);

  const KynzaLoaderSize({
    required this.diameter,
    required this.particleCount,
    required this.strokeRatio,
  });

  /// Diamètre total du composant (taille de l'orbite).
  final double diameter;

  /// Nombre de particules en orbite — varie selon la taille pour rester
  /// lisible (5 sur un loader 16px reste net, 7 sur un 48px reste élégant).
  final int particleCount;

  /// Ratio utilisé pour calculer le rayon de chaque particule individuelle.
  final double strokeRatio;
}
