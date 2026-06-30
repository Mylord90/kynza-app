import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../widgets/kynza_auth_card.dart';

String _maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email;
  final name = email.substring(0, at);
  final domain = email.substring(at);
  final visible = name.length >= 3 ? name.substring(0, 3) : name;
  return '$visible***$domain';
}

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _cooldownSeconds = 60;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _secondsLeft = _cooldownSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  Future<void> _resend(String email) async {
    await ref.read(authNotifierProvider.notifier).resendVerification(email);
    KynzaHaptics.success();
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final email =
        ref
            .watch(authNotifierProvider)
            .valueOrNull
            ?.whenOrNull(
              emailNotVerified: (pendingEmail, userId) => pendingEmail,
            ) ??
        '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: KynzaAuthCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.authVerifyEmailTitle,
                    style: AppTypography.h1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.authVerifyEmailSubtitle(_maskEmail(email)),
                    style: AppTypography.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.authVerifyEmailCheckSpam,
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  KynzaButton(
                    label: _secondsLeft > 0
                        ? l10n.authVerifyEmailResendCooldown(
                            _secondsLeft.toString().padLeft(2, '0'),
                          )
                        : l10n.authVerifyEmailResendButton,
                    variant: KynzaButtonVariant.secondary,
                    onPressed: _secondsLeft > 0 || email.isEmpty
                        ? null
                        : () => _resend(email),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go(RouteNames.register),
                      child: Text(l10n.authVerifyEmailChangeAddress),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
