import 'package:flutter/material.dart';
import '../../../core/localization/extensions/build_context_l10n_extension.dart';
import 'kynza_loader_controller.dart';
import 'kynza_loader_painter.dart';
import 'models/loader_size.dart';
import 'models/loader_theme.dart';
import 'models/loader_variant.dart';

/// Composant de chargement officiel et unique de KYNZA — "Orbite Dorée".
/// Remplace tout usage de `CircularProgressIndicator` dans l'application.
///
/// ```dart
/// const KynzaLoader(size: KynzaLoaderSize.medium)
/// ```
///
/// Voir `docs/LOADER_GUIDE.md` pour les variantes d'usage
/// ([KynzaLoaderInline], [KynzaLoaderFullscreen], [KynzaLoaderOverlay],
/// [KynzaLoaderButton]) et le mapping de tailles.
class KynzaLoader extends StatefulWidget {
  const KynzaLoader({
    super.key,
    this.size = KynzaLoaderSize.medium,
    this.theme = KynzaLoaderTheme.standard,
    this.variant = KynzaLoaderVariant.orbit,
    this.semanticLabel,
  });

  final KynzaLoaderSize size;
  final KynzaLoaderTheme theme;
  final KynzaLoaderVariant variant;

  /// Label pour TalkBack/VoiceOver. Si `null`, utilise
  /// `context.l10n.commonLoading`.
  final String? semanticLabel;

  @override
  State<KynzaLoader> createState() => _KynzaLoaderState();
}

class _KynzaLoaderState extends State<KynzaLoader>
    with SingleTickerProviderStateMixin {
  late final KynzaLoaderController _loaderController = KynzaLoaderController(
    vsync: this,
  );

  @override
  void dispose() {
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Semantics(
      label: widget.semanticLabel ?? context.l10n.commonLoading,
      liveRegion: true,
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size.diameter,
          height: widget.size.diameter,
          child: AnimatedBuilder(
            animation: _loaderController.animation,
            builder: (context, _) {
              return CustomPaint(
                painter: KynzaLoaderPainter(
                  progress: _loaderController.animation.value,
                  size: widget.size,
                  theme: widget.theme,
                  variant: widget.variant,
                  reduceMotion: mediaQuery.disableAnimations,
                  highContrast: mediaQuery.highContrast,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
