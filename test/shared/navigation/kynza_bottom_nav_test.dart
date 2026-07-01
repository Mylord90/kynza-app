import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kynza/shared/navigation/kynza_bottom_nav.dart';
import 'package:kynza/shared/navigation/kynza_nav_item.dart';

void main() {
  const items = [
    KynzaNavItem(icon: Icons.calendar_today_outlined, label: 'Calendrier'),
    KynzaNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    KynzaNavItem(icon: Icons.people_outline, label: 'Clients'),
  ];

  Widget buildTestWidget({
    required int currentIndex,
    required ValueChanged<int> onItemTapped,
    List<KynzaNavItem> navItems = items,
    bool disableAnimations = false,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          bottomNavigationBar: KynzaBottomNav(
            items: navItems,
            currentIndex: currentIndex,
            onItemTapped: onItemTapped,
          ),
        ),
      ),
    );
  }

  group('KynzaBottomNav', () {
    testWidgets('renders every item label', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(currentIndex: 0, onItemTapped: (_) {}),
      );

      expect(find.text('Calendrier'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Clients'), findsOneWidget);
    });

    testWidgets('onItemTapped fires with the tapped index', (tester) async {
      int? tappedIndex;
      await tester.pumpWidget(
        buildTestWidget(
          currentIndex: 0,
          onItemTapped: (index) => tappedIndex = index,
        ),
      );

      await tester.tap(find.text('Clients'));
      await tester.pump();

      expect(tappedIndex, 2);
    });

    testWidgets('marks the active item as selected for Semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        buildTestWidget(currentIndex: 1, onItemTapped: (_) {}),
      );

      final dashboardSemantics = tester.getSemantics(find.text('Dashboard'));
      expect(dashboardSemantics.flagsCollection.isSelected, Tristate.isTrue);

      handle.dispose();
    });

    testWidgets('shows a badge when badgeCount > 0', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          currentIndex: 0,
          onItemTapped: (_) {},
          navItems: const [
            KynzaNavItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              badgeCount: 3,
            ),
          ],
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('caps the badge at 99+', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          currentIndex: 0,
          onItemTapped: (_) {},
          navItems: const [
            KynzaNavItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              badgeCount: 250,
            ),
          ],
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('respects reduce motion without throwing', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          currentIndex: 0,
          onItemTapped: (_) {},
          disableAnimations: true,
        ),
      );

      await tester.tap(find.text('Clients'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('disposes animation controllers cleanly on unmount', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(currentIndex: 0, onItemTapped: (_) {}),
      );
      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
    });
  });
}
