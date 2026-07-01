import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/widgets/kynza_widgets.dart';

/// Tap zone → image_picker → bytes handed back via [onPicked].
/// Used for the circular logo (120dp), the 16:9 cover, and the
/// portfolio grid's "+" add tile.
class MediaUploadButton extends StatelessWidget {
  const MediaUploadButton({
    super.key,
    required this.onPicked,
    this.previewBytes,
    this.previewUrl,
    this.isLoading = false,
    this.isCircular = false,
    this.width,
    this.height,
    this.icon = Icons.add_a_photo_outlined,
    this.label,
  });

  final void Function(Uint8List bytes, String ext) onPicked;
  final Uint8List? previewBytes;
  final String? previewUrl;
  final bool isLoading;
  final bool isCircular;
  final double? width;
  final double? height;
  final IconData icon;
  final String? label;

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';
    onPicked(bytes, ext);
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = isCircular ? null : AppRadius.lg_;
    final hasPreview = previewBytes != null || previewUrl != null;

    return InkWell(
      onTap: isLoading ? null : _pick,
      customBorder: isCircular ? const CircleBorder() : null,
      borderRadius: borderRadius,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.border),
          image: hasPreview
              ? DecorationImage(
                  image: previewBytes != null
                      ? MemoryImage(previewBytes!)
                      : NetworkImage(previewUrl!) as ImageProvider,
                  fit: BoxFit.cover,
                )
              : null,
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const KynzaLoader(size: KynzaLoaderSize.medium)
            : hasPreview
            ? Container(
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.35),
                  shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: borderRadius,
                ),
                child: const Icon(Icons.edit, color: AppColors.textPrimary),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: AppColors.textSecondary, size: 28),
                  if (label != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      label!,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
