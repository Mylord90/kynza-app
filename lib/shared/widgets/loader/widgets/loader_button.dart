import 'package:flutter/material.dart';
import '../kynza_loader.dart';
import '../models/loader_size.dart';
import '../models/loader_theme.dart';

/// Remplace l'état de chargement des boutons (`KynzaButton.isLoading`,
/// `KynzaOAuthButton.isLoading`, etc.) — taille du bouton inchangée, pas de
/// layout shift.
class KynzaLoaderButton extends StatelessWidget {
  const KynzaLoaderButton({super.key, this.onGoldBackground = false});

  /// `true` quand le bouton a un fond gold plein (ex. `KynzaButtonVariant
  /// .primary`) — le dégradé gold standard y serait peu lisible, on bascule
  /// sur [KynzaLoaderTheme.onGoldBackground].
  final bool onGoldBackground;

  @override
  Widget build(BuildContext context) {
    return KynzaLoader(
      size: KynzaLoaderSize.small,
      theme: onGoldBackground
          ? KynzaLoaderTheme.onGoldBackground
          : KynzaLoaderTheme.standard,
    );
  }
}
