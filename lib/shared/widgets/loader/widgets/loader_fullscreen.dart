import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../kynza_loader.dart';
import '../models/loader_size.dart';

/// Pour écrans de chargement complets (transition de route, écran dédié).
/// Fond `AppColors.background` plein écran, loader fullscreen centré.
class KynzaLoaderFullscreen extends StatelessWidget {
  const KynzaLoaderFullscreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const KynzaLoader(size: KynzaLoaderSize.fullscreen),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(message!, style: AppTypography.body),
            ],
          ],
        ),
      ),
    );
  }
}
