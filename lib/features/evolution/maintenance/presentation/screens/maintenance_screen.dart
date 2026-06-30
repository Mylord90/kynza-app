import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_spacing.dart';
import '../../../../../core/constants/app_typography.dart';
import '../../application/providers/maintenance_providers.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Re-check every 30 s — when maintenance ends the router redirect fires
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => ref.invalidate(maintenanceStatusProvider),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(maintenanceStatusProvider);
    final window = statusAsync.valueOrNull;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  size: 72,
                  color: AppColors.warning,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  window?.title ?? 'Maintenance en cours',
                  style: AppTypography.h1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  window?.message ??
                      'L\'application est temporairement indisponible. '
                          'Nous reviendrons très bientôt.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (window?.endsAt != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _EndsAtChip(endsAt: window!.endsAt!),
                ],
                const SizedBox(height: AppSpacing.xl),
                TextButton.icon(
                  onPressed: () => ref.invalidate(maintenanceStatusProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Vérifier à nouveau'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EndsAtChip extends StatelessWidget {
  const _EndsAtChip({required this.endsAt});

  final DateTime endsAt;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('HH:mm', 'fr').format(endsAt.toLocal());
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Fin prévue vers $formatted',
        style: AppTypography.label.copyWith(color: AppColors.warning),
      ),
    );
  }
}