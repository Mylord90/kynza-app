import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_branding.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/auth_redirect.dart';
import '../../../auth/application/providers/auth_notifier_provider.dart';

/// Minimum display time, independent of how fast the session check resolves.
/// NEVER show a loading indicator here, and NEVER make network calls beyond
/// the session restore already triggered by reading authNotifierProvider.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _minDisplay = Duration(milliseconds: 1500);

  late final AnimationController _markController;
  late final Animation<double> _markScale;
  late final AnimationController _wordmarkController;
  late final Animation<double> _wordmarkOpacity;
  late final AnimationController _shimmerController;

  bool _minDisplayElapsed = false;

  @override
  void initState() {
    super.initState();

    _markController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _markScale = CurvedAnimation(
      parent: _markController,
      curve: Curves.elasticOut,
    );

    _wordmarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _wordmarkOpacity = CurvedAnimation(
      parent: _wordmarkController,
      curve: Curves.easeIn,
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _markController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _wordmarkController.forward();
    });

    Future.delayed(_minDisplay, () {
      if (!mounted) return;
      setState(() => _minDisplayElapsed = true);
      _maybeNavigate();
    });
  }

  @override
  void dispose() {
    _markController.dispose();
    _wordmarkController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _maybeNavigate() {
    if (!_minDisplayElapsed) return;
    final authValue = ref.read(authNotifierProvider);
    if (authValue.isLoading) return;

    final authState = authValue.valueOrNull;
    final destination = authState == null
        ? _unauthenticatedDestination()
        : authState.when(
            initial: () => _unauthenticatedDestination(),
            loading: () => null,
            error: (_) => _unauthenticatedDestination(),
            unauthenticated: () => _unauthenticatedDestination(),
            authenticated: redirectAfterAuth,
            emailNotVerified: (email, userId) => RouteNames.verifyEmail,
            profileIncomplete: (userId) => RouteNames.completeProfile,
          );
    if (destination != null) context.go(destination);
  }

  /// First-ever unauthenticated visit goes through the onboarding carousel;
  /// every subsequent one (or once it's been completed) goes straight to
  /// login. Reuses `SessionService.markOnboardingDone`/`isOnboardingDone`,
  /// which existed but was never wired to anything until this screen.
  String _unauthenticatedDestination() {
    final seenOnboarding = ref.read(sessionServiceProvider).isOnboardingDone();
    return seenOnboarding ? RouteNames.login : RouteNames.onboarding;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      if (!next.isLoading) _maybeNavigate();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _markScale,
              child: Image.asset(
                AppBranding.logoFull,
                width: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FadeTransition(
              opacity: _wordmarkOpacity,
              child: Text(
                'KYNZA',
                style: AppTypography.mono.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FadeTransition(
              opacity: _wordmarkOpacity,
              child: SizedBox(
                width: 120,
                height: 3,
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        colors: const [
                          AppColors.primaryVariant,
                          AppColors.primary,
                          AppColors.primaryVariant,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment(-1 + 4 * _shimmerController.value, 0),
                        end: Alignment(1 + 4 * _shimmerController.value, 0),
                      ).createShader(rect),
                      child: Container(color: AppColors.primary),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
