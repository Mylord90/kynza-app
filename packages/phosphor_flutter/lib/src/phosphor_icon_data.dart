library phosphor_flutter;

// Local patch (see packages/phosphor_flutter/README_PATCH.md): upstream 2.1.0
// (the latest release on pub.dev) declared `class PhosphorIconData extends
// IconData`, which no longer compiles once the Flutter SDK made IconData a
// `final class` (final classes can't be extended *or* implemented outside
// their own library — there is no subtype relationship to IconData left
// available to this package).
//
// Every phosphor_icons_*.dart file has been mechanically rewritten to build
// plain `const IconData(...)` values directly instead of wrapping them in
// these classes, so PhosphorIcons.xxx constants are real IconData values
// wherever KYNZA uses them (Icon(...), KynzaNavItem.icon, etc.). These two
// classes are kept only because phosphor_icon.dart's `PhosphorIcon` widget
// still references `PhosphorDuotoneIconData` in a type check — since no
// value is ever actually constructed as one anymore, that check is now dead
// code and the widget's automatic dual-layer duotone rendering is inert
// (KYNZA never used it — grep confirmed zero "Duotone" usage in lib/).
class PhosphorIconData {
  const PhosphorIconData(this.codePoint, this.style);

  final int codePoint;
  final String style;
}

class PhosphorFlatIconData extends PhosphorIconData {
  const PhosphorFlatIconData(int codePoint, String style) : super(codePoint, style);
}

class PhosphorDuotoneIconData extends PhosphorIconData {
  const PhosphorDuotoneIconData(int codePoint, this.secondary)
      : super(codePoint, 'Duotone');

  final PhosphorIconData secondary;
}
