import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/kynza_widgets.dart';
import '../../application/providers/legal_providers.dart';
import '../widgets/legal_labels.dart';

class PolicyViewerScreen extends ConsumerWidget {
  const PolicyViewerScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(policyViewerDataProvider(slug));
    final accepting = ref.watch(legalAcceptanceNotifierProvider).isLoading;
    final isOnline = ref.watch(connectivityProvider).value ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: dataAsync.valueOrNull != null
            ? Text(legalDocumentTypeLabel(context, dataAsync.value!.document.type))
            : null,
      ),
      body: Column(
        children: [
          const KynzaOfflineBanner(),
          Expanded(
            child: dataAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: KynzaSkeleton(height: 400),
              ),
              error: (_, __) => KynzaErrorState(
                message: context.l10n.policyViewerLoadError,
                onRetry: () =>
                    ref.invalidate(policyViewerDataProvider(slug)),
              ),
              data: (data) {
                if (data == null || data.version == null) {
                  return KynzaErrorState(
                    message: context.l10n.policyViewerLoadError,
                    onRetry: () =>
                        ref.invalidate(policyViewerDataProvider(slug)),
                  );
                }
                final version = data.version!;
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    SelectableText(
                      version.contentMarkdown,
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextButton(
                      onPressed: () => context.push(
                        RouteNames.legalDocumentHistoryPath(slug),
                      ),
                      child: Text(context.l10n.policyViewerHistoryLink),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (data.isAccepted)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            context.l10n.policyViewerAcceptedLabel,
                            style: AppTypography.body,
                          ),
                        ],
                      )
                    else
                      KynzaButton(
                        label: context.l10n.policyViewerAcceptButton,
                        isLoading: accepting,
                        onPressed: () async {
                          try {
                            await ref
                                .read(legalAcceptanceNotifierProvider.notifier)
                                .acceptCurrentVersion(version.id!);
                            if (!context.mounted) return;
                            ref.invalidate(policyViewerDataProvider(slug));
                            showKynzaToast(
                              context,
                              message: isOnline
                                  ? context.l10n.policyViewerAcceptedLabel
                                  : context
                                        .l10n
                                        .policyViewerAcceptedOfflineLabel,
                              level: ToastLevel.success,
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            showKynzaToast(
                              context,
                              message: e is AppException
                                  ? e.message
                                  : context.l10n.policyViewerLoadError,
                              level: ToastLevel.error,
                            );
                          }
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
