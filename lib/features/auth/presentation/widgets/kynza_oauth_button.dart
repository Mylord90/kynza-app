import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../shared/widgets/kynza_spinner.dart';

enum KynzaOAuthProvider { google, facebook, apple }

class KynzaOAuthButton extends StatefulWidget {
  const KynzaOAuthButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  final KynzaOAuthProvider provider;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<KynzaOAuthButton> createState() => _KynzaOAuthButtonState();
}

class _KynzaOAuthButtonState extends State<KynzaOAuthButton> {
  bool _hovered = false;

  String _label(BuildContext context) => switch (widget.provider) {
    KynzaOAuthProvider.google => context.l10n.authOauthGoogleLabel,
    KynzaOAuthProvider.facebook => context.l10n.authOauthFacebookLabel,
    KynzaOAuthProvider.apple => context.l10n.authOauthAppleLabel,
  };

  Widget get _icon => switch (widget.provider) {
    KynzaOAuthProvider.google => Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w900,
          fontSize: 14,
        ),
      ),
    ),
    KynzaOAuthProvider.facebook => Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.facebook, color: Colors.white, size: 18),
    ),
    KynzaOAuthProvider.apple => const Icon(
      Icons.apple,
      color: Colors.white,
      size: 22,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: disabled || widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: AppDurations.standard,
          transform: Matrix4.translationValues(
            0,
            _hovered && !disabled ? -1 : 0,
            0,
          ),
          height: 52,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: AppRadius.button_,
            border: Border.all(
              color: _hovered && !disabled
                  ? AppColors.primary
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Opacity(
            opacity: disabled ? 0.5 : 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.isLoading ? const KynzaSpinner(size: 20) : _icon,
                const SizedBox(width: 12),
                Text(
                  _label(context),
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
