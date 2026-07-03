import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/offline_sync_providers.dart';
import '../../core/services/crash_reporting_service.dart';
import '../../features/legal/application/providers/legal_providers.dart';

/// Non-blocking banner (R03 offline-first). Shows "Hors connexion" while
/// disconnected, then a brief "Synchronisé" confirmation on reconnect.
/// Also the app-wide trigger point for replaying every offline outbox
/// (legal acceptances + the generic mutation outbox — reviews, profile
/// edits, data-deletion requests) — this is the one place that already
/// observes the offline→online transition.
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
      ref
          .read(legalAcceptanceNotifierProvider.notifier)
          .flushOfflineQueue()
          .catchError(CrashReportingService.recordError);
      ref
          .read(offlineSyncCoordinatorProvider)
          .flush()
          .catchError(CrashReportingService.recordError);
    }
    _previouslyConnected = isConnected;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                      ? l10n.offlineBannerSynced
                      : l10n.offlineBannerMessage,
                  style: AppTypography.bodySmall,
                ),
              )
            : null,
      ),
    );
  }
}
