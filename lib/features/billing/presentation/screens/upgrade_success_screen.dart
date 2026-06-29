import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

class UpgradeSuccessScreen extends StatefulWidget {
  const UpgradeSuccessScreen({super.key});

  @override
  State<UpgradeSuccessScreen> createState() => _UpgradeSuccessScreenState();
}

class _UpgradeSuccessScreenState extends State<UpgradeSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppDurations.spring,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.elasticOut,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 96,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Demande envoyée ! 🎉',
                style: AppTypography.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Notre équipe va vous contacter sous 24h pour finaliser '
                'votre mise à niveau.',
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'En attendant, vous pouvez continuer à utiliser KYNZA.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              KynzaButton(
                label: 'Retour au dashboard',
                onPressed: () => context.go(RouteNames.homeOwner),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
