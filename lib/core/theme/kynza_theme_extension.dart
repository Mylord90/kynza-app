import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Holds the JetBrains Mono text style used for monetary amounts and
/// monospace content. Declared as a [ThemeExtension] so the font is
/// resolved once via [GoogleFonts] and shared through [ThemeData].
@immutable
class KynzaThemeExtension extends ThemeExtension<KynzaThemeExtension> {
  const KynzaThemeExtension({required this.monoTextStyle});

  final TextStyle monoTextStyle;

  static KynzaThemeExtension get standard =>
      KynzaThemeExtension(monoTextStyle: GoogleFonts.jetBrainsMono());

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
