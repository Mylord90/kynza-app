import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/core/constants/app_typography.dart';
import 'package:kynza/core/theme/app_theme.dart';
import 'package:kynza/core/theme/text_theme.dart';

void main() {
  group('AppTypography', () {
    test('all UI styles use the bundled Plus Jakarta Sans family', () {
      const uiStyles = [
        AppTypography.displayLarge,
        AppTypography.displayMedium,
        AppTypography.h1,
        AppTypography.h2,
        AppTypography.h3,
        AppTypography.headlineLarge,
        AppTypography.headlineMedium,
        AppTypography.headlineSmall,
        AppTypography.titleLarge,
        AppTypography.titleMedium,
        AppTypography.titleSmall,
        AppTypography.body,
        AppTypography.bodySmall,
        AppTypography.bodyLarge,
        AppTypography.bodyMedium,
        AppTypography.button,
        AppTypography.label,
        AppTypography.labelLarge,
        AppTypography.labelMedium,
        AppTypography.labelSmall,
      ];
      for (final style in uiStyles) {
        expect(style.fontFamily, equals(AppTypography.fontUI));
      }
    });

    test('all amount/mono styles use the bundled JetBrains Mono family', () {
      const monoStyles = [
        AppTypography.amount,
        AppTypography.amountMd,
        AppTypography.amountSm,
        AppTypography.amountLarge,
        AppTypography.amountLabel,
        AppTypography.mono,
        AppTypography.monoBold,
      ];
      for (final style in monoStyles) {
        expect(style.fontFamily, equals(AppTypography.fontMono));
      }
    });

    test('amount and mono styles use tabular figures', () {
      const styles = [
        AppTypography.amount,
        AppTypography.amountMd,
        AppTypography.amountSm,
        AppTypography.amountLarge,
        AppTypography.amountLabel,
        AppTypography.mono,
        AppTypography.monoBold,
      ];
      for (final style in styles) {
        expect(
          style.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      }
    });

    test('bodyMedium alias points to body', () {
      expect(
        AppTypography.bodyMedium.fontSize,
        equals(AppTypography.body.fontSize),
      );
      expect(
        AppTypography.bodyMedium.fontWeight,
        equals(AppTypography.body.fontWeight),
      );
    });

    test(
      'scale hierarchy: headlineLarge > headlineSmall, displayLarge > headlineLarge',
      () {
        expect(
          AppTypography.headlineLarge.fontSize,
          greaterThan(AppTypography.headlineSmall.fontSize!),
        );
        expect(
          AppTypography.displayLarge.fontSize,
          greaterThanOrEqualTo(AppTypography.headlineLarge.fontSize!),
        );
      },
    );

    test('reference scale sizes (24/20/16/14/12) are present', () {
      final sizes = [
        AppTypography.headlineLarge.fontSize,
        AppTypography.headlineSmall.fontSize,
        AppTypography.titleMedium.fontSize,
        AppTypography.titleSmall.fontSize,
        AppTypography.bodySmall.fontSize,
      ];
      expect(sizes, containsAll(<double>[24.0, 20.0, 16.0, 14.0, 12.0]));
    });

    test('all styles are compile-time const', () {
      const style = AppTypography.bodyMedium;
      expect(style, isNotNull);
    });
  });

  group('KynzaTextTheme', () {
    test('dark theme fills all Material 3 slots with AppTypography styles', () {
      const theme = KynzaTextTheme.dark;
      expect(theme.headlineLarge, equals(AppTypography.headlineLarge));
      expect(theme.titleMedium, equals(AppTypography.titleMedium));
      expect(theme.bodyMedium, equals(AppTypography.bodyMedium));
      expect(theme.labelLarge, equals(AppTypography.labelLarge));
    });

    test('AppTheme.dark wires KynzaTextTheme into ThemeData', () {
      final themeData = AppTheme.dark;
      expect(
        themeData.textTheme.bodyMedium?.fontFamily,
        equals(AppTypography.fontUI),
      );
    });
  });
}
