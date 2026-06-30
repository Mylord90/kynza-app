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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authNotifierProvider.notifier)
        .signIn(_emailController.text.trim(), _passwordController.text);
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
                      l10n.authLoginTitle,
                      style: AppTypography.h1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.authLoginSubtitle,
                      style: AppTypography.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    KynzaTextField(
                      label: l10n.authLoginEmailLabel,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    KynzaPasswordField(
                      controller: _passwordController,
                      textInputAction: TextInputAction.done,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            context.push(RouteNames.forgotPassword),
                        child: Text(l10n.authLoginForgotPasswordLink),
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
                      label: l10n.authLoginSubmitButton,
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
                        onPressed: () => context.push(RouteNames.register),
                        child: Text(l10n.authLoginNoAccountLink),
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
