import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:super_app/models/barber_shop.dart';
import 'package:super_app/models/service_hub_kind.dart';
import 'package:super_app/providers/app_provider.dart';
import 'package:super_app/screens/service_hub_screen.dart';

/// Integratsiya tekshiruvi: haqiqiy ServiceHubScreen orqali (foydalanuvchi
/// kategoriya kartasini bosganda ochiladigan ekran) yangi dizayn chiqishini
/// va _catalogEntries ma'lumotlari to'g'ri o'tishini tasdiqlaydi.
void main() {
  test('Talab: BARCHA xizmatlarda yangi dizayn yoqilgan', () {
    // Konditsioner "Texnika ustasi" ichiga, kompUsta va "yana" esa
    // "Boshqa xizmatlar" ichiga birlashtirilgandan keyin — 22 ta xizmat
    // qoldi va HAMMASIDA yangi dizayn ishlaydi.
    expect(kNewHubDesignKinds.length, ServiceHubKind.values.length,
        reason: 'eski dizaynda qolgan xizmat bo\'lmasligi kerak');
    for (final k in ServiceHubKind.values) {
      expect(kNewHubDesignKinds.contains(k), isTrue,
          reason: '${k.name} yangi dizaynda bo\'lishi kerak');
    }
  });

  test('Konditsioner alohida kategoriya sifatida olib tashlangan', () {
    final names = ServiceHubKind.values.map((e) => e.name).toList();
    expect(names, isNot(contains('konditsioner')));
    expect(names, isNot(contains('kompUsta')));
    expect(names, isNot(contains('yana')));
    // Uning o'rniga texnika ustasi va boshqa xizmatlar bor.
    expect(names, contains('texnikaUstasi'));
    expect(names, contains('boshqa'));
  });

  test('BarberShop modeli teg va holat manbaini beradi', () {
    final shop = BarberShop(
      id: '7',
      name: 'Zamon Barber',
      address: 'Yunusobod',
      phoneNumber: '+998901234567',
      rating: 4.8,
      reviewCount: 92,
      latitude: 41.31,
      longitude: 69.24,
      images: const [],
      services: const ['Erkaklar kesimi', 'Soqol olish'],
      prices: const {'Erkaklar kesimi': 50000},
      barbers: const [],
    );

    // ProviderListRow ishlatadigan maydonlar mavjud va to'g'ri turdami.
    expect(shop.services, isNotEmpty, reason: 'teglar manbai');
    expect(shop.isOpenNow(), isA<bool>(), reason: 'ochiq/yopiq holati');
    expect(shop.priceRangeLabel(), isNotEmpty, reason: 'narx yorlig\'i');
    expect(shop.id, isNotEmpty, reason: 'noyob id manbai');
  });

  testWidgets('Sartarosh hub ochilganda yangi dizayn ko\'rinadi',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>(
        create: (_) => AppProvider(),
        child: const MaterialApp(
          home: ServiceHubScreen(
            kind: ServiceHubKind.sartarosh,
            accentColor: Color(0xFF2563EB),
          ),
        ),
      ),
    );
    // Ma'lumot yuklanishini kutamiz (tarmoq yo'q — bo'sh natija qaytadi).
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Yangi dizayn belgilari: qidiruv + "Xaritadan" + pastki tugmalar.
    expect(find.text('Xaritadan'), findsOneWidget,
        reason: 'yangi dizayn ochilishi kerak');
    expect(find.text('Saqlanganlar'), findsOneWidget);
    expect(find.text('Filtrlar'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('"Boshqa xizmatlar" ham yangi dizaynda ochiladi',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>(
        create: (_) => AppProvider(),
        child: const MaterialApp(
          home: ServiceHubScreen(
            kind: ServiceHubKind.boshqa,
            accentColor: Color(0xFF2563EB),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Ilgari bu bo'lim BO'SH edi — endi to'liq ekran ishlaydi.
    expect(find.text('Xaritadan'), findsOneWidget);
    expect(find.text('Saqlanganlar'), findsOneWidget);
    expect(find.text('Filtrlar'), findsOneWidget);
  });
}
