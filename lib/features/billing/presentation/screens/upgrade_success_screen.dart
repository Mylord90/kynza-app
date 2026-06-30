import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
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
              Text(
                context.l10n.upgradeSuccessTitle,
                style: AppTypography.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.upgradeSuccessSubtitle,
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.upgradeSuccessNote,
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              KynzaButton(
                label: context.l10n.upgradeSuccessBackButton,
                onPressed: () => context.go(RouteNames.homeOwner),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
