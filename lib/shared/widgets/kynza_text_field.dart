import 'package:flutter/material.dart';
import '../../core/constants/app_typography.dart';

class KynzaTextField extends StatelessWidget {
  const KynzaTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.prefixWidget,
    this.onChanged,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final Widget? prefixWidget;
  final void Function(String)? onChanged;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      style: AppTypography.body.copyWith(height: 1),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        prefix: prefixWidget,
      ),
    );
  }
}
