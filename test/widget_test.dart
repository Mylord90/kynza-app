import 'package:flutter_test/flutter_test.dart';

import 'package:kynza/main.dart';

void main() {
  testWidgets('KynzaApp displays the KYNZA splash text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KynzaApp());

    expect(find.text('KYNZA'), findsOneWidget);
  });
}
