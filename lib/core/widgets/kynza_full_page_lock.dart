import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../enums/user_role.dart';

/// Shown when a user reaches a route they don't have the role for.
/// NEVER redirect silently away from a route mismatch — always show this.
class KynzaFullPageLock extends StatelessWidget {
  const KynzaFullPageLock({super.key, required this.requiredRole});

  final UserRole requiredRole;

  String get _roleLabel => switch (requiredRole) {
    UserRole.owner => 'Propriétaire',
    UserRole.manager => 'Manager',
    UserRole.staff => 'Staff',
    UserRole.client => 'Client',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Accès réservé',
                style: AppTypography.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Cette page est réservée au rôle $_roleLabel.',
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/'),
                child: const Text('← Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
