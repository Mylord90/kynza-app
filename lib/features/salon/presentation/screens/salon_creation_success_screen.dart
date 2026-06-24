import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

class SalonCreationSuccessScreen extends StatefulWidget {
  const SalonCreationSuccessScreen({super.key});

  @override
  State<SalonCreationSuccessScreen> createState() =>
      _SalonCreationSuccessScreenState();
}

class _SalonCreationSuccessScreenState extends State<SalonCreationSuccessScreen>
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
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Votre salon est créé ! 🎉',
                style: AppTypography.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Ajoutez maintenant vos services',
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              KynzaButton(
                label: 'Configurer mes services →',
                onPressed: () => context.go(RouteNames.ownerServices),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
