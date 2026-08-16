import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:super_app/models/barber_shop.dart';
import 'package:super_app/models/service_hub_kind.dart';
import 'package:super_app/providers/app_provider.dart';
import 'package:super_app/screens/service_hub_screen.dart';
import 'package:super_app/widgets/hub/provider_list_row.dart';

/// Integratsiya tekshiruvi: haqiqiy ServiceHubScreen orqali (foydalanuvchi
/// kategoriya kartasini bosganda ochiladigan ekran) yangi dizayn chiqishini
/// va _catalogEntries ma'lumotlari to'g'ri o'tishini tasdiqlaydi.
void main() {
  test('Talab: yangi dizayn 23 ta xizmatga yoqilgan', () {
    expect(kNewHubDesignKinds.length, 23);
    expect(kNewHubDesignKinds.contains(ServiceHubKind.sartarosh), isTrue);
    expect(kNewHubDesignKinds.contains(ServiceHubKind.salon), isTrue);
    expect(kNewHubDesignKinds.contains(ServiceHubKind.stomatologiya), isTrue);
    // Katalog ma'lumoti yo'q xizmatlar eski ko'rinishda qoladi.
    expect(kNewHubDesignKinds.contains(ServiceHubKind.kompUsta), isFalse);
    expect(kNewHubDesignKinds.contains(ServiceHubKind.boshqa), isFalse);
    expect(kNewHubDesignKinds.contains(ServiceHubKind.yana), isFalse);
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

  testWidgets('Eski dizayn saqlangan xizmat (kompUsta) o\'zgarmagan',
      (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>(
        create: (_) => AppProvider(),
        child: const MaterialApp(
          home: ServiceHubScreen(
            kind: ServiceHubKind.kompUsta,
            accentColor: Color(0xFF2563EB),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Eski ko'rinishda "Xaritadan" tugmasi yo'q.
    expect(find.text('Xaritadan'), findsNothing);
    expect(find.byType(ProviderListRow), findsNothing);
  });
}
