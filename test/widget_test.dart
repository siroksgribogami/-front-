// This is a basic Flutter widget test for ARThouse app.

import 'package:flutter_test/flutter_test.dart';

import 'package:art_front/main.dart';

void main() {
  testWidgets('ARThouse app startup test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ARThouseApp());

    // Verify that login screen is shown
    expect(find.text('Войти'), findsOneWidget);
  });
}
