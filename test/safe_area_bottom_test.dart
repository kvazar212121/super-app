// Ekran pastidagi tugmalar KESILIB qolmasligi.
//
// HAQIQIY SHIKOYAT: kaloriya "Taom tahlili" ekranida "Saqlash"
// tugmasi Android'ning pastki uch tugmasi ostida qolib kesilgan va
// foydalanuvchi uni bosa olmagan.
//
// Sabab: `GlassScaffold` `SafeArea(bottom: false)` ishlatardi, ya'ni
// pastdagi tizim paneli uchun joy qoldirmasdi. Bu 44 ta ekranga
// taalluqli edi.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:super_app/providers/app_provider.dart';
import 'package:super_app/widgets/glass/glass_scaffold.dart';

/// Pastda tizim paneli bor qurilmani taqlid qiladi.
const _tizimPaneli = EdgeInsets.only(bottom: 48, top: 24);

Widget _qur({required Widget body, bool safeAreaBottom = true}) {
  return MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
    child: MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: _tizimPaneli,
          viewPadding: _tizimPaneli,
        ),
        child: GlassScaffold(
          title: 'Sinov',
          safeAreaBottom: safeAreaBottom,
          body: body,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Ekran oxiridagi tugma tizim paneli ustida qoladi', (
    tester,
  ) async {
    await tester.pumpWidget(
      _qur(
        body: ListView(
          children: [
            const SizedBox(height: 600),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () {},
                child: const Text('Saqlash'),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Ro'yxatni oxirigacha suramiz.
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    final tugma = tester.getRect(find.text('Saqlash'));
    // Ekran balandligi 800, pastda 48px tizim paneli bor.
    // Tugmaning pastki cheti 752 dan oshmasligi kerak.
    expect(
      tugma.bottom,
      lessThanOrEqualTo(800 - 48 + 1),
      reason: 'tugma tizim paneli ostida qolib kesilmasligi kerak',
    );
    expect(find.text('Saqlash'), findsOneWidget);
  });

  testWidgets('safeAreaBottom: false — xarita butun ekranni egallaydi', (
    tester,
  ) async {
    // Xaritada bosiladigan tugma yo'q, pastda bo'sh chiziq esa
    // xaritani kesib qo'yadi.
    await tester.pumpWidget(
      _qur(
        safeAreaBottom: false,
        body: Container(key: const Key('xarita'), color: Colors.green),
      ),
    );
    await tester.pumpAndSettle();

    final xaritali = tester.getRect(find.byKey(const Key('xarita'))).bottom;

    // Endi STANDART holatni o'lchaymiz va farqni solishtiramiz.
    // Aniq piksel AppBar balandligiga bog'liq, shuning uchun ikki
    // holat orasidagi FARQ tekshiriladi: u aynan tizim paneli
    // balandligi (48px) bo'lishi kerak.
    await tester.pumpWidget(
      _qur(body: Container(key: const Key('xarita'), color: Colors.green)),
    );
    await tester.pumpAndSettle();
    final oddiy = tester.getRect(find.byKey(const Key('xarita'))).bottom;

    expect(
      xaritali - oddiy,
      equals(48.0),
      reason: 'safeAreaBottom: false da tizim paneli joyi ham ishlatiladi',
    );
  });

  testWidgets('Standart holat — pastki joy AJRATILADI', (tester) async {
    // Standart `true` bo'lishi shart: 44 ta ekran shu skaffoldni
    // ishlatadi va har birida tugma bo'lishi mumkin.
    await tester.pumpWidget(
      _qur(body: Container(key: const Key('tana'), color: Colors.blue)),
    );
    await tester.pumpAndSettle();

    final tana = tester.getRect(find.byKey(const Key('tana')));
    // Tana pastdagi 48px tizim panelidan yuqorida tugashi kerak.
    expect(
      tana.bottom,
      lessThanOrEqualTo(800.0 - 48),
      reason: 'standart holatda pastki panel uchun joy qoldiriladi',
    );
  });

  testWidgets('embeddedInShell rejimida ham joy ajratiladi', (tester) async {
    // Tab ichidagi ekranlar (Buyurtmalarim, Savdo) ham shu qoidaga
    // bo'ysunadi.
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AppProvider())],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              padding: _tizimPaneli,
              viewPadding: _tizimPaneli,
            ),
            child: GlassScaffold(
              title: 'Tab',
              embeddedInShell: true,
              body: Container(key: const Key('tana'), color: Colors.blue),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tana = tester.getRect(find.byKey(const Key('tana')));
    expect(tana.bottom, lessThanOrEqualTo(800.0 - 48));
  });
}
