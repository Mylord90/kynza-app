import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum AvatarSize { xs, sm, md, lg, xl }

extension on AvatarSize {
  double get px => switch (this) {
    AvatarSize.xs => 24,
    AvatarSize.sm => 32,
    AvatarSize.md => 40,
    AvatarSize.lg => 56,
    AvatarSize.xl => 80,
  };
}

class KynzaAvatar extends StatelessWidget {
  const KynzaAvatar({
    super.key,
    this.avatarUrl,
    required this.fullName,
    this.size = AvatarSize.md,
    this.isOwner = false,
  });

  final String? avatarUrl;
  final String fullName;
  final AvatarSize size;
  final bool isOwner;

  String get _initial {
    final trimmed = fullName.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final px = size.px;
    final content = ClipOval(
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? Container(
              width: px,
              height: px,
              color: AppColors.surfaceVariant,
              alignment: Alignment.center,
              child: Text(
                _initial,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: px * 0.4,
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: avatarUrl!,
              width: px,
              height: px,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: AppColors.surfaceVariant),
              errorWidget: (context, url, error) => Container(
                width: px,
                height: px,
                color: AppColors.surfaceVariant,
                alignment: Alignment.center,
                child: Text(
                  _initial,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ),
    );

    if (!isOwner) return SizedBox(width: px, height: px, child: content);

    return Container(
      width: px,
      height: px,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      padding: const EdgeInsets.all(2),
      child: content,
    );
  }
}
