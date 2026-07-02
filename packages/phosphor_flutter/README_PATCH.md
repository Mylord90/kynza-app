# Local patch — phosphor_flutter 2.1.0

Vendored from pub.dev `phosphor_flutter` 2.1.0 (the latest published version —
no newer release exists as of this patch). Wired via `dependency_overrides`
in the root `pubspec.yaml`.

## Why

`lib/src/phosphor_icon_data.dart` declared `class PhosphorIconData extends
IconData`. The Flutter SDK's `IconData` (`packages/flutter/lib/src/widgets/icon_data.dart`)
is now a `final class`, so it can no longer be extended — this broke every
debug/release build (`Target kernel_snapshot_program failed`).

## What changed

Only `lib/src/phosphor_icon_data.dart`: `PhosphorIconData` now `implements
IconData` instead of extending it, redeclaring `codePoint`, `fontFamily`,
`fontPackage`, `matchTextDirection`, `fontFamilyFallback`, `==`, `hashCode`,
and `toString()` to match `IconData`'s contract exactly. No other file in
this package was touched. `PhosphorFlatIconData`/`PhosphorDuotoneIconData`
(which extend `PhosphorIconData`, not `IconData` directly) needed no changes.

## Removing this patch

If `phosphor_flutter` ships a fixed release upstream, delete
`packages/phosphor_flutter/` and the `dependency_overrides` entry in the
root `pubspec.yaml`, then bump the version constraint.
