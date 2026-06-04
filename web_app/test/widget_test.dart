import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tellus_demo/main.dart';

void main() {
  testWidgets('App builds MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const TellusDemoApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
