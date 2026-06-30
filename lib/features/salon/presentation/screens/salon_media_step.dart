import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/extensions/build_context_l10n_extension.dart';
import '../../../../core/models/salon_media_model.dart';
import '../widgets/media_upload_button.dart';

typedef PortfolioDraft = (Uint8List bytes, String ext, MediaType type);

class SalonMediaStep extends StatelessWidget {
  const SalonMediaStep({
    super.key,
    required this.logoBytes,
    required this.coverBytes,
    required this.portfolio,
    required this.onLogoPicked,
    required this.onCoverPicked,
    required this.onPortfolioAdded,
    required this.onPortfolioRemoved,
  });

  final Uint8List? logoBytes;
  final Uint8List? coverBytes;
  final List<PortfolioDraft> portfolio;
  final void Function(Uint8List bytes, String ext) onLogoPicked;
  final void Function(Uint8List bytes, String ext) onCoverPicked;
  final void Function(Uint8List bytes, String ext) onPortfolioAdded;
  final void Function(int index) onPortfolioRemoved;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(l10n.salonMediaStepLogoLabel, style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: MediaUploadButton(
            isCircular: true,
            width: 120,
            height: 120,
            previewBytes: logoBytes,
            onPicked: onLogoPicked,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.salonMediaStepCoverLabel, style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: MediaUploadButton(
            previewBytes: coverBytes,
            onPicked: onCoverPicked,
            label: l10n.salonMediaStepAddCoverLabel,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.salonMediaStepGalleryLabel(portfolio.length, 20), style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
          ),
          itemCount: portfolio.length + (portfolio.length < 20 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == portfolio.length) {
              return MediaUploadButton(
                onPicked: onPortfolioAdded,
                icon: Icons.add,
              );
            }
            final (bytes, _, type) = portfolio[index];
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: MemoryImage(bytes),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: type == MediaType.video
                      ? const Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onPortfolioRemoved(index),
                    child: const CircleAvatar(
                      radius: 11,
                      backgroundColor: AppColors.background,
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
