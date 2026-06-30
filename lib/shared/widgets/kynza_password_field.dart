import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/localization/extensions/build_context_l10n_extension.dart';

enum _Strength { empty, weak, fair, good, strong }

class KynzaPasswordField extends StatefulWidget {
  const KynzaPasswordField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.textInputAction,
    this.onChanged,
    this.showStrengthBar = false,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;
  final bool showStrengthBar;

  @override
  State<KynzaPasswordField> createState() => _KynzaPasswordFieldState();
}

class _KynzaPasswordFieldState extends State<KynzaPasswordField> {
  bool _obscure = true;
  _Strength _strength = _Strength.empty;

  _Strength _evaluate(String value) {
    if (value.isEmpty) return _Strength.empty;
    var score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'\d').hasMatch(value)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value)) score++;
    return switch (score) {
      0 || 1 => _Strength.weak,
      2 => _Strength.fair,
      3 => _Strength.good,
      _ => _Strength.strong,
    };
  }

  Color _colorFor(_Strength s) => switch (s) {
    _Strength.empty => AppColors.border,
    _Strength.weak => AppColors.error,
    _Strength.fair => AppColors.warning,
    _Strength.good => AppColors.primary,
    _Strength.strong => AppColors.success,
  };

  int _filledSegments(_Strength s) => switch (s) {
    _Strength.empty => 0,
    _Strength.weak => 1,
    _Strength.fair => 2,
    _Strength.good => 3,
    _Strength.strong => 4,
  };

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = widget.label ?? context.l10n.fieldPasswordLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _obscure,
          textInputAction: widget.textInputAction,
          onChanged: (value) {
            if (widget.showStrengthBar) {
              setState(() => _strength = _evaluate(value));
            }
            widget.onChanged?.call(value);
          },
          decoration: InputDecoration(
            labelText: effectiveLabel,
            hintText: widget.hint,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        if (widget.showStrengthBar) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i < _filledSegments(_strength)
                          ? _colorFor(_strength)
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
