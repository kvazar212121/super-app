import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/main.dart';

void main() {
  testWidgets('Super App - bosh sahifa yuklanadi', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // MaterialApp mavjudligini tekshirish
    expect(find.byType(MaterialApp), findsOneWidget);

    // MainScreen yuklanganligini tekshirish
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Super App - bottom navigation ko\'rsatiladi', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // BottomNavigationBar mavjud
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
