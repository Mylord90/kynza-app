import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Affiche/masque l'overlay de chargement global depuis n'importe quel
/// provider/notifier sans dépendance directe au widget tree — pour les
/// opérations async longues qui doivent bloquer toute interaction (export
/// PDF/CSV, traitement de paiement).
///
/// À intégrer dans le widget racine de l'app, au-dessus de
/// `MaterialApp.router` :
/// ```dart
/// Stack(
///   children: [
///     MaterialApp.router(...),
///     if (ref.watch(loaderOverlayProvider)) const KynzaLoaderOverlay(),
///   ],
/// )
/// ```
class LoaderOverlayNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void show() => state = true;

  void hide() => state = false;
}

final loaderOverlayProvider = NotifierProvider<LoaderOverlayNotifier, bool>(
  LoaderOverlayNotifier.new,
);
