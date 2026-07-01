import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/shared/widgets/loader/kynza_loader_painter.dart';
import 'package:kynza/shared/widgets/loader/models/loader_size.dart';
import 'package:kynza/shared/widgets/loader/models/loader_theme.dart';
import 'package:kynza/shared/widgets/loader/models/loader_variant.dart';

KynzaLoaderPainter _painter({
  double progress = 0.0,
  KynzaLoaderSize size = KynzaLoaderSize.medium,
  KynzaLoaderTheme theme = KynzaLoaderTheme.standard,
  KynzaLoaderVariant variant = KynzaLoaderVariant.orbit,
  bool reduceMotion = false,
  bool highContrast = false,
}) {
  return KynzaLoaderPainter(
    progress: progress,
    size: size,
    theme: theme,
    variant: variant,
    reduceMotion: reduceMotion,
    highContrast: highContrast,
  );
}

Future<Uint8List> _rasterize(
  KynzaLoaderPainter painter,
  Size canvasSize,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, canvasSize);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    canvasSize.width.round(),
    canvasSize.height.round(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return bytes!.buffer.asUint8List();
}

void main() {
  group('KynzaLoaderPainter.shouldRepaint', () {
    test('returns true when progress changes', () {
      final oldDelegate = _painter(progress: 0.1);
      final newDelegate = _painter(progress: 0.2);
      expect(newDelegate.shouldRepaint(oldDelegate), isTrue);
    });

    test('returns false when nothing changes', () {
      final oldDelegate = _painter(progress: 0.5);
      final newDelegate = _painter(progress: 0.5);
      expect(newDelegate.shouldRepaint(oldDelegate), isFalse);
    });

    test('returns true when reduceMotion changes', () {
      final oldDelegate = _painter(reduceMotion: false);
      final newDelegate = _painter(reduceMotion: true);
      expect(newDelegate.shouldRepaint(oldDelegate), isTrue);
    });

    test('returns true when highContrast changes', () {
      final oldDelegate = _painter(highContrast: false);
      final newDelegate = _painter(highContrast: true);
      expect(newDelegate.shouldRepaint(oldDelegate), isTrue);
    });

    test('returns true when size changes', () {
      final oldDelegate = _painter(size: KynzaLoaderSize.small);
      final newDelegate = _painter(size: KynzaLoaderSize.large);
      expect(newDelegate.shouldRepaint(oldDelegate), isTrue);
    });

    test('returns true when variant changes', () {
      final oldDelegate = _painter(variant: KynzaLoaderVariant.orbit);
      final newDelegate = _painter(variant: KynzaLoaderVariant.pulse);
      expect(newDelegate.shouldRepaint(oldDelegate), isTrue);
    });
  });

  group('KynzaLoaderPainter determinism', () {
    // picture.toImage() is a real (non-FakeAsync) GPU round-trip — it never
    // completes inside testWidgets' fake async zone unless run through
    // tester.runAsync().
    testWidgets('orbit variant renders identical pixels for identical inputs '
        '(organic angle offsets are fixed, not random)', (tester) async {
      await tester.runAsync(() async {
        const canvasSize = Size(48, 48);
        final framePixels = await _rasterize(
          _painter(progress: 0.37, size: KynzaLoaderSize.large),
          canvasSize,
        );
        final framePixelsAgain = await _rasterize(
          _painter(progress: 0.37, size: KynzaLoaderSize.large),
          canvasSize,
        );

        expect(framePixels, equals(framePixelsAgain));
      });
    });

    testWidgets('pulse variant renders identical pixels for identical inputs', (
      tester,
    ) async {
      await tester.runAsync(() async {
        const canvasSize = Size(28, 28);
        final a = await _rasterize(
          _painter(progress: 0.6, variant: KynzaLoaderVariant.pulse),
          canvasSize,
        );
        final b = await _rasterize(
          _painter(progress: 0.6, variant: KynzaLoaderVariant.pulse),
          canvasSize,
        );

        expect(a, equals(b));
      });
    });

    testWidgets('different progress values produce different pixels', (
      tester,
    ) async {
      await tester.runAsync(() async {
        const canvasSize = Size(48, 48);
        final a = await _rasterize(_painter(progress: 0.0), canvasSize);
        final b = await _rasterize(_painter(progress: 0.5), canvasSize);

        expect(a, isNot(equals(b)));
      });
    });
  });
}
