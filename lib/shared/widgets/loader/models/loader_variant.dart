/// Variantes de présentation du `KynzaLoader`.
///
/// `linear` (progression déterministe) n'a aucun cas d'usage dans le projet
/// actuellement — documenté comme extension future dans
/// `docs/LOADER_GUIDE.md`, non codé en V1.
enum KynzaLoaderVariant {
  /// Particules en orbite — variante par défaut.
  orbit,

  /// Un seul cercle qui pulse doucement — pour les très petits espaces.
  pulse,
}
