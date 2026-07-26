import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:friday_app/main.dart';

void main() {
  testWidgets('App renders FridayApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FridayApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
