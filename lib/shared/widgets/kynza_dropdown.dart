import 'package:flutter/material.dart';
import '../../core/constants/app_typography.dart';

class KynzaDropdown<T> extends StatelessWidget {
  const KynzaDropdown({
    super.key,
    this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.validator,
  });

  final String? label;
  final String? hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      validator: validator,
      style: AppTypography.body.copyWith(height: 1),
      decoration: InputDecoration(labelText: label, hintText: hint),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(itemLabel(e))))
          .toList(),
      onChanged: onChanged,
    );
  }
}
