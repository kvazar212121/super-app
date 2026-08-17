import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/screens/my_jobs_screen.dart';

void main() {
  testWidgets('E\'lonlar ekrani: alohida ochilganda o\'z AppBar\'i bo\'ladi',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyJobsScreen()));
    await tester.pump();

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Mening e\'lonlarim'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('E\'lonlar ekrani: tab ichida AppBar takrorlanmaydi',
      (WidgetTester tester) async {
    // "Buyurtmalarim" ekrani ichida tab sifatida ochilganda o'z sarlavhasi
    // bo'lmasligi kerak, aks holda ikkita AppBar ustma-ust chiqadi.
    await tester.pumpWidget(
      const MaterialApp(home: MyJobsScreen(embedded: true)),
    );
    await tester.pump();

    expect(find.byType(AppBar), findsNothing);
    // E'lon berish tugmasi esa ikkala holatda ham bo'ladi
    expect(find.text('E\'lon berish'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  });
}
