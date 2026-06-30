import 'package:flutter/material.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../widgets/province_selector.dart';

class SalonLocationStep extends StatelessWidget {
  const SalonLocationStep({
    super.key,
    required this.formKey,
    required this.addressController,
    required this.province,
    required this.commune,
    required this.onProvinceChanged,
    required this.onCommuneChanged,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController addressController;
  final String? province;
  final String? commune;
  final void Function(String?) onProvinceChanged;
  final void Function(String?) onCommuneChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ProvinceSelector(
            province: province,
            commune: commune,
            onProvinceChanged: onProvinceChanged,
            onCommuneChanged: onCommuneChanged,
          ),
          const SizedBox(height: 16),
          KynzaTextField(
            label: context.l10n.salonLocationStepAddressLabel,
            hint: context.l10n.salonLocationHint,
            controller: addressController,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
