import 'package:flutter/material.dart';
import '../../../../core/constants/burundi_provinces.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../shared/widgets/kynza_dropdown.dart';

class ProvinceSelector extends StatelessWidget {
  const ProvinceSelector({
    super.key,
    required this.province,
    required this.commune,
    required this.onProvinceChanged,
    required this.onCommuneChanged,
  });

  final String? province;
  final String? commune;
  final void Function(String?) onProvinceChanged;
  final void Function(String?) onCommuneChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final communes = BurundiProvinces.communesFor(province);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KynzaDropdown<String>(
          label: l10n.provinceSelectorProvinceLabel,
          value: province,
          items: BurundiProvinces.provinces,
          itemLabel: (p) => p,
          validator: (v) => v == null ? l10n.provinceSelectorProvinceRequired : null,
          onChanged: (value) {
            onProvinceChanged(value);
            onCommuneChanged(null);
          },
        ),
        const SizedBox(height: 16),
        KynzaDropdown<String>(
          label: l10n.provinceSelectorCommuneLabel,
          value: communes.contains(commune) ? commune : null,
          items: communes,
          itemLabel: (c) => c,
          validator: (v) => v == null ? l10n.provinceSelectorCommuneRequired : null,
          onChanged: onCommuneChanged,
        ),
      ],
    );
  }
}
