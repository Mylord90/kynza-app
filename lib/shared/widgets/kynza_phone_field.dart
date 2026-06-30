import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/constants/kynza_constants.dart';
import '../../core/localization/extensions/build_context_l10n_extension.dart';

class KynzaPhoneField extends StatelessWidget {
  const KynzaPhoneField({
    super.key,
    this.controller,
    this.validator,
    this.onChanged,
  });

  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      keyboardType: TextInputType.phone,
      maxLength: 8,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: l10n.fieldPhoneLabel,
        helperText: l10n.fieldPhoneHelper,
        counterText: '',
        prefix: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            KynzaConstants.phonePrefix,
            style: AppTypography.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
