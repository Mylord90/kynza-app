import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/l10n/app_localizations.dart';
import 'package:kynza/shared/widgets/loader/kynza_loader.dart';
import 'package:kynza/shared/widgets/loader/kynza_loader_painter.dart';
import 'package:kynza/shared/widgets/loader/models/loader_size.dart';
import 'package:kynza/shared/widgets/loader/widgets/loader_button.dart';
import 'package:kynza/shared/widgets/loader/widgets/loader_fullscreen.dart';
import 'package:kynza/shared/widgets/loader/widgets/loader_inline.dart';
import 'package:kynza/shared/widgets/loader/widgets/loader_overlay.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('KynzaLoader disposes its AnimationController without error', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const KynzaLoader()));
    await tester.pump(const Duration(milliseconds: 200));

    // Unmounting mid-animation must not throw (AnimationController.dispose).
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('KynzaLoader passes reduceMotion through to the painter', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const KynzaLoader(), disableAnimations: true),
    );
    await tester.pump();

    final customPaint = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is KynzaLoaderPainter,
      ),
    );
    final painter = customPaint.painter! as KynzaLoaderPainter;
    expect(painter.reduceMotion, isTrue);
  });

  testWidgets('KynzaLoader has the correct Semantics label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(const KynzaLoader()));
    await tester.pump();

    expect(find.bySemanticsLabel('Chargement…'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('KynzaLoader honors a custom semanticLabel override', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(const KynzaLoader(semanticLabel: 'Synchronisation')),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Synchronisation'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('KynzaLoaderInline displays the optional message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const KynzaLoaderInline(message: 'Chargement des disponibilités')),
    );
    await tester.pump();

    expect(find.text('Chargement des disponibilités'), findsOneWidget);
    expect(find.byType(KynzaLoader), findsOneWidget);
  });

  testWidgets('KynzaLoaderFullscreen uses the KYNZA background color', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const KynzaLoaderFullscreen()));
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.backgroundColor, const Color(0xFF09090B));
    expect(
      tester.widget<KynzaLoader>(find.byType(KynzaLoader)).size,
      KynzaLoaderSize.fullscreen,
    );
  });

  testWidgets('KynzaLoaderOverlay blocks back navigation (canPop: false)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const KynzaLoaderOverlay()));
    await tester.pump();

    final popScope = tester.widget<PopScope>(find.byType(PopScope));
    expect(popScope.canPop, isFalse);
  });

  testWidgets('KynzaLoaderButton renders a small KynzaLoader', (tester) async {
    await tester.pumpWidget(_wrap(const KynzaLoaderButton()));
    await tester.pump();

    expect(
      tester.widget<KynzaLoader>(find.byType(KynzaLoader)).size,
      KynzaLoaderSize.small,
    );
  });
}
