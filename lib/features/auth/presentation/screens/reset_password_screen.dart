import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/auth_errors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../widgets/kynza_auth_card.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _exchanging = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _exchangeCode());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _exchangeCode() async {
    final code = GoRouterState.of(context).uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      _showToast(context.l10n.authResetPasswordInvalidLink);
      if (mounted) context.go(RouteNames.forgotPassword);
      return;
    }
    try {
      await SupabaseService.auth.exchangeCodeForSession(code);
      if (mounted) setState(() => _exchanging = false);
    } catch (e) {
      _showToast(getAuthErrorMessage(e));
      if (mounted) context.go(RouteNames.forgotPassword);
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    await ref
        .read(authNotifierProvider.notifier)
        .updatePassword(_passwordController.text);
    if (!mounted) return;
    final error = ref
        .read(authNotifierProvider)
        .valueOrNull
        ?.whenOrNull(error: (message) => message);
    setState(() => _isSubmitting = false);
    if (error != null) {
      _showToast(error);
      return;
    }
    _showToast(context.l10n.authResetPasswordSuccess);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_exchanging) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: KynzaLoadingOverlay(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KynzaAuthCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.authResetPasswordTitle,
                style: AppTypography.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              KynzaPasswordField(
                label: l10n.authResetPasswordNewLabel,
                controller: _passwordController,
                validator: Validators.password,
                showStrengthBar: true,
              ),
              const SizedBox(height: AppSpacing.md),
              KynzaPasswordField(
                label: l10n.authResetPasswordConfirmLabel,
                controller: _confirmController,
                validator: (v) =>
                    Validators.confirmPassword(v, _passwordController.text),
              ),
              const SizedBox(height: AppSpacing.lg),
              KynzaButton(
                label: l10n.authResetPasswordSubmitButton,
                onPressed: _submit,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
