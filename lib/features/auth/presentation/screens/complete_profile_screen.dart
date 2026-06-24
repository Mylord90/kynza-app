import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/utils/auth_errors.dart';
import '../../../../core/utils/auth_redirect.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../widgets/kynza_auth_card.dart';

class _RoleOption {
  const _RoleOption(this.role, this.emoji, this.label, this.subtitle);
  final UserRole role;
  final String emoji;
  final String label;
  final String subtitle;
}

const _roleOptions = [
  _RoleOption(UserRole.client, '👤', 'Client', 'Réservez des soins'),
  _RoleOption(UserRole.staff, '✂️', 'Staff', 'Praticien dans un salon'),
  _RoleOption(UserRole.owner, '🏪', 'Propriétaire', 'Gérez votre salon'),
];

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  UserRole _selectedRole = UserRole.client;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final metadata = ref
        .read(supabaseClientProvider)
        .auth
        .currentUser
        ?.userMetadata;
    final oauthName = metadata?['full_name'] as String?;
    if (oauthName != null) _fullNameController.text = oauthName;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final fullName = _fullNameController.text.trim();

    setState(() => _isSubmitting = true);
    final client = ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    final nameParts = fullName.split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1
        ? nameParts.sublist(1).join(' ')
        : null;
    final phone = _phoneController.text.trim();

    try {
      await client
          .from('users')
          .update({
            'full_name': fullName,
            'first_name': firstName,
            'last_name': lastName,
            'phone': phone.isEmpty ? null : phone,
            'role': _selectedRole.name,
            'profile_completed': true,
          })
          .eq('id', userId);

      await client.auth.refreshSession();
      ref.invalidate(currentUserProfileProvider);
      await ref.read(authNotifierProvider.notifier).refreshProfile();

      if (!mounted) return;
      final profile = await ref.read(currentUserProfileProvider.future);
      if (profile != null && mounted) context.go(redirectAfterAuth(profile));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(getAuthErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: KynzaAuthCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Finalisez votre profil',
                      style: AppTypography.h1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Quelques informations pour démarrer',
                      style: AppTypography.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    KynzaTextField(
                      label: 'Nom complet',
                      controller: _fullNameController,
                      validator: Validators.fullName,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    KynzaPhoneField(controller: _phoneController),
                    const SizedBox(height: AppSpacing.lg),
                    for (final option in _roleOptions) ...[
                      KynzaCard(
                        isSelected: _selectedRole == option.role,
                        onTap: () =>
                            setState(() => _selectedRole = option.role),
                        child: Row(
                          children: [
                            Text(
                              option.emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(option.label, style: AppTypography.h3),
                                  Text(
                                    option.subtitle,
                                    style: AppTypography.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (_selectedRole == option.role)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    KynzaButton(
                      label: 'Commencer →',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
