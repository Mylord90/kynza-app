import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../kynza_loader.dart';
import '../models/loader_size.dart';
import '../models/loader_theme.dart';

/// Overlay bloquant — pour opérations critiques qui ne doivent jamais être
/// interrompues (échange OAuth, vérification d'invitation/parrainage,
/// traitement de paiement). Non dismissable : `PopScope(canPop: false)`.
class KynzaLoaderOverlay extends StatelessWidget {
  const KynzaLoaderOverlay({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: ColoredBox(
        color: KynzaLoaderTheme.overlay.backgroundDim,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const KynzaLoader(size: KynzaLoaderSize.large),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  message!,
                  style: AppTypography.body,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
