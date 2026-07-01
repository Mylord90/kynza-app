import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../kynza_loader.dart';
import '../models/loader_size.dart';

/// Pour usage dans le flux normal d'un widget — listes, cards, sections,
/// gardes de route. Centré automatiquement, padding cohérent KYNZA.
class KynzaLoaderInline extends StatelessWidget {
  const KynzaLoaderInline({
    super.key,
    this.size = KynzaLoaderSize.medium,
    this.message,
  });

  final KynzaLoaderSize size;

  /// Message optionnel affiché sous le loader (ex. "Chargement des
  /// disponibilités...").
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KynzaLoader(size: size),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(message!, style: AppTypography.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
