import 'package:flutter/material.dart';
import '../constants/app_typography.dart';

/// Holds the JetBrains Mono text style used for monetary amounts and
/// monospace content, sourced from the locally bundled font (see
/// [AppTypography.fontMono]) and shared through [ThemeData].
@immutable
class KynzaThemeExtension extends ThemeExtension<KynzaThemeExtension> {
  const KynzaThemeExtension({required this.monoTextStyle});

  final TextStyle monoTextStyle;

  static const KynzaThemeExtension standard = KynzaThemeExtension(
    monoTextStyle: TextStyle(fontFamily: AppTypography.fontMono),
  );

  @override
  KynzaThemeExtension copyWith({TextStyle? monoTextStyle}) =>
      KynzaThemeExtension(monoTextStyle: monoTextStyle ?? this.monoTextStyle);

  @override
  KynzaThemeExtension lerp(
    ThemeExtension<KynzaThemeExtension>? other,
    double t,
  ) {
    if (other is! KynzaThemeExtension) return this;
    return KynzaThemeExtension(
      monoTextStyle:
          TextStyle.lerp(monoTextStyle, other.monoTextStyle, t) ??
          monoTextStyle,
    );
  }
}
