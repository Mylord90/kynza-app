import 'package:flutter/material.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

class SalonInfoStep extends StatelessWidget {
  const SalonInfoStep({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.sloganController,
    required this.descriptionController,
    required this.phoneController,
    required this.emailController,
    required this.facebookController,
    required this.instagramController,
    required this.tiktokController,
    required this.whatsappController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController sloganController;
  final TextEditingController descriptionController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController facebookController;
  final TextEditingController instagramController;
  final TextEditingController tiktokController;
  final TextEditingController whatsappController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          KynzaTextField(
            label: 'Nom du salon *',
            controller: nameController,
            maxLength: 100,
            validator: (v) => Validators.required(v, 'Nom du salon'),
          ),
          const SizedBox(height: 16),
          KynzaTextField(
            label: 'Slogan',
            controller: sloganController,
            maxLength: 150,
          ),
          const SizedBox(height: 16),
          KynzaTextField(
            label: 'Description',
            controller: descriptionController,
            maxLength: 500,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          KynzaPhoneField(
            controller: phoneController,
            validator: Validators.phone,
          ),
          const SizedBox(height: 16),
          KynzaTextField(
            label: 'Email',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v == null || v.isEmpty ? null : Validators.email(v),
          ),
          const SizedBox(height: 24),
          const Text('Réseaux sociaux', style: AppTypography.h3),
          const SizedBox(height: 12),
          KynzaTextField(label: 'Facebook', controller: facebookController),
          const SizedBox(height: 12),
          KynzaTextField(label: 'Instagram', controller: instagramController),
          const SizedBox(height: 12),
          KynzaTextField(label: 'TikTok', controller: tiktokController),
          const SizedBox(height: 12),
          KynzaTextField(label: 'WhatsApp', controller: whatsappController),
        ],
      ),
    );
  }
}
