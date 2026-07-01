import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/l10n/app_localizations.dart';
import 'package:kynza/shared/widgets/loader/kynza_loader.dart';
import 'package:kynza/shared/widgets/loader/models/loader_size.dart';
import 'package:kynza/shared/widgets/loader/widgets/loader_inline.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets(
    'KynzaLoader survives a prolonged animation cycle with no exceptions '
    '(simulated 5s at ~60fps)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(const KynzaLoader(size: KynzaLoaderSize.large)),
      );

      const frame = Duration(milliseconds: 16);
      for (
        var elapsed = Duration.zero;
        elapsed < const Duration(seconds: 5);
        elapsed += frame
      ) {
        await tester.pump(frame);
      }

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'multiple simultaneous KynzaLoader instances do not throw or jank',
    (tester) async {
      // Tall enough that ListView.builder lays out all 12 items instead of
      // lazily culling the ones outside the default 600-logical-pixel
      // viewport.
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          ListView.builder(
            itemCount: 12,
            itemBuilder: (context, index) =>
                const KynzaLoaderInline(size: KynzaLoaderSize.small),
          ),
        ),
      );

      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(tester.takeException(), isNull);
      expect(find.byType(KynzaLoader), findsNWidgets(12));
    },
  );
}
