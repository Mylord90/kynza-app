import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/auth_redirect.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../widgets/kynza_auth_card.dart';
import '../widgets/kynza_auth_divider.dart';
import '../widgets/kynza_oauth_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authNotifierProvider.notifier)
        .signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _fullNameController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    ref.listen(authNotifierProvider, (previous, next) {
      next.whenData((state) {
        state.whenOrNull(
          authenticated: (user) async {
            final route = await resolvePostAuthRoute(
              ref.read(sessionServiceProvider),
              user,
            );
            if (context.mounted) context.go(route);
          },
          emailNotVerified: (email, userId) =>
              context.go(RouteNames.verifyEmail),
          profileIncomplete: (userId) => context.go(RouteNames.completeProfile),
        );
      });
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final errorMessage = authState.valueOrNull?.whenOrNull(
      error: (message) => message,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: KynzaAuthCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.authRegisterTitle,
                      style: AppTypography.h1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.authRegisterSubtitle,
                      style: AppTypography.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    KynzaTextField(
                      label: l10n.authRegisterFullNameLabel,
                      controller: _fullNameController,
                      textInputAction: TextInputAction.next,
                      validator: Validators.fullName,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    KynzaTextField(
                      label: l10n.authRegisterEmailLabel,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    KynzaPasswordField(
                      controller: _passwordController,
                      textInputAction: TextInputAction.next,
                      validator: Validators.password,
                      showStrengthBar: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    KynzaPasswordField(
                      label: l10n.authRegisterConfirmPasswordLabel,
                      controller: _confirmController,
                      textInputAction: TextInputAction.done,
                      validator: (v) => Validators.confirmPassword(
                        v,
                        _passwordController.text,
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        errorMessage,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    KynzaButton(
                      label: l10n.authRegisterSubmitButton,
                      onPressed: _submit,
                      isLoading: isLoading,
                    ),
                    const KynzaAuthDivider(),
                    KynzaOAuthButton(
                      provider: KynzaOAuthProvider.google,
                      isLoading: isLoading,
                      onPressed: () => ref
                          .read(authNotifierProvider.notifier)
                          .signInWithGoogle(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Tooltip(
                      message: l10n.authOauthComingSoon,
                      child: const KynzaOAuthButton(
                        provider: KynzaOAuthProvider.facebook,
                        onPressed: null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Tooltip(
                      message: l10n.authOauthComingSoon,
                      child: const KynzaOAuthButton(
                        provider: KynzaOAuthProvider.apple,
                        onPressed: null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: TextButton(
                        // go() (not pop()) — register is sometimes reached
                        // via a full stack replace (e.g. AcceptInvitationScreen
                        // redirecting an unauthenticated staff member here),
                        // leaving nothing to pop back to.
                        onPressed: () => context.go(RouteNames.login),
                        child: Text(l10n.authRegisterAlreadyHaveAccountLink),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
