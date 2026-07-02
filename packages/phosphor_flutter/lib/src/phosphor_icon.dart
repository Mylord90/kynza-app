library phosphor_flutter;

import 'package:flutter/material.dart';

class PhosphorIcon extends Icon {
  const PhosphorIcon(
    IconData icon, {
    Key? key,
    double? size,
    double? fill,
    double? weight,
    double? grade,
    double? opticalSize,
    Color? color,
    List<Shadow>? shadows,
    String? semanticLabel,
    TextDirection? textDirection,
    this.duotoneSecondaryOpacity = 0.20,
    this.duotoneSecondaryColor,
  }) : super(
          icon,
          color: color,
          fill: fill,
          grade: grade,
          key: key,
          opticalSize: opticalSize,
          semanticLabel: semanticLabel,
          shadows: shadows,
          size: size,
          textDirection: textDirection,
          weight: weight,
        );

  final double duotoneSecondaryOpacity;
  final Color? duotoneSecondaryColor;

  // Local patch (see packages/phosphor_flutter/README_PATCH.md): the
  // dual-layer duotone rendering this override used to provide required
  // PhosphorIcons.xxxDuotone constants to be a PhosphorDuotoneIconData
  // instance carrying a `secondary` IconData. Since IconData is now a
  // `final class`, none of the icon-set constants can be anything but a
  // plain IconData anymore (see phosphor_icons_duotone.dart), so this
  // widget never receives a PhosphorDuotoneIconData and always renders as
  // a single-layer icon — unused in KYNZA regardless (zero "Duotone" call
  // sites in lib/).
}
