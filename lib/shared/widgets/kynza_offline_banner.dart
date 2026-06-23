import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_typography.dart';
import '../../core/providers/app_providers.dart';

/// Non-blocking banner (R03 offline-first). Shows "Hors connexion" while
/// disconnected, then a brief "Synchronisé" confirmation on reconnect.
class KynzaOfflineBanner extends ConsumerStatefulWidget {
  const KynzaOfflineBanner({super.key});

  @override
  ConsumerState<KynzaOfflineBanner> createState() => _KynzaOfflineBannerState();
}

class _KynzaOfflineBannerState extends ConsumerState<KynzaOfflineBanner> {
  bool? _previouslyConnected;
  bool _showSynced = false;
  Timer? _syncedTimer;

  @override
  void dispose() {
    _syncedTimer?.cancel();
    super.dispose();
  }

  void _handleConnectivity(bool isConnected) {
    if (_previouslyConnected == false && isConnected) {
      setState(() => _showSynced = true);
      _syncedTimer?.cancel();
      _syncedTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showSynced = false);
      });
    }
    _previouslyConnected = isConnected;
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider);
    final isConnected = connectivity.valueOrNull ?? true;

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _handleConnectivity(isConnected),
    );

    final visible = !isConnected || _showSynced;

    return AnimatedSize(
      duration: AppDurations.medium,
      curve: Curves.easeOut,
      child: SizedBox(
        height: visible ? 40 : 0,
        width: double.infinity,
        child: visible
            ? Container(
                color: AppColors.surfaceVariant,
                alignment: Alignment.center,
                child: Text(
                  isConnected
                      ? '✓ Synchronisé'
                      : '📴 Hors connexion • Données en cache',
                  style: AppTypography.bodySmall,
                ),
              )
            : null,
      ),
    );
  }
}
