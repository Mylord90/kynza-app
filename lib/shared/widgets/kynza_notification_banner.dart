import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/extensions/build_context_l10n_extension.dart';

/// Slides down from the top, 64dp tall, auto-dismisses after 4s. Shown via
/// an [OverlayEntry] so it floats above the current screen regardless of
/// the active route (used for foreground FCM messages).
void showKynzaNotificationBanner(
  BuildContext context, {
  required String title,
  required String subtitle,
  VoidCallback? onTap,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  void dismiss() {
    if (entry.mounted) entry.remove();
  }

  entry = OverlayEntry(
    builder: (context) => _BannerContent(
      title: title,
      subtitle: subtitle,
      onTap: () {
        dismiss();
        onTap?.call();
      },
      onDismissed: dismiss,
    ),
  );

  overlay.insert(entry);
  Future.delayed(const Duration(seconds: 4), dismiss);
}

class _BannerContent extends StatefulWidget {
  const _BannerContent({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onDismissed,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  @override
  State<_BannerContent> createState() => _BannerContentState();
}

class _BannerContentState extends State<_BannerContent>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppDurations.rich,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: Tween(begin: const Offset(0, -1), end: Offset.zero).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: AppRadius.md_,
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppRadius.md_,
                    border: const Border(
                      left: BorderSide(color: AppColors.primary, width: 3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title, style: AppTypography.h3),
                            Text(
                              widget.subtitle,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: context.l10n.commonClose,
                        onPressed: widget.onDismissed,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
