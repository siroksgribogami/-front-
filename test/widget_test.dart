// Smoke test: Приделе root widget mounts.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:art_front/main.dart';

void main() {
  testWidgets('PridelApp mounts MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const PridelApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
