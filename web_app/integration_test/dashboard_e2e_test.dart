import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tellus_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dashboard loads infrastructure data and timeline works', (tester) async {
    await tester.pumpWidget(const TellusDemoApp());
    await tester.pumpAndSettle(const Duration(seconds: 8));

    expect(find.byKey(const ValueKey('dashboard_header')), findsOneWidget);
    expect(find.textContaining('TELLUS'), findsOneWidget);

    expect(find.byKey(const ValueKey('map_panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('side_panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('timeline_slider')), findsOneWidget);

    final dateLabel = find.byKey(const ValueKey('timeline_date_label'));
    expect(dateLabel, findsOneWidget);
    final initialDate = (tester.widget<Text>(dateLabel).data ?? '').trim();
    expect(initialDate.isNotEmpty, isTrue);

    await tester.tap(find.byKey(const ValueKey('region_chip_tateyama')));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.textContaining('立山'), findsWidgets);

    final slider = find.byKey(const ValueKey('timeline_slider'));
    await tester.drag(slider, const Offset(-180, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    final updatedDate = (tester.widget<Text>(dateLabel).data ?? '').trim();
    expect(updatedDate.isNotEmpty, isTrue);

    await tester.tap(find.byKey(const ValueKey('region_chip_joganji')));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.textContaining('常願寺川'), findsWidgets);
  });

  testWidgets('map markers reflect two distinct regions', (tester) async {
    await tester.pumpWidget(const TellusDemoApp());
    await tester.pumpAndSettle(const Duration(seconds: 8));

    expect(find.textContaining('常願寺川'), findsWidgets);
    expect(find.textContaining('立山'), findsWidgets);
  });
}
