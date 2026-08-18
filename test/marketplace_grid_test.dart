// Chatdagi savdo GRIDI — haqiqiy widgetlar bilan.
//
// Foydalanuvchi talabi: qidiruv natijasi chatда vertikal tugmalar
// emas, 2 ustunli KARTALAR (20 tagacha) bo'lib chiqsin. Har kartada
// rasm, nom, NARX (doim so'mda), holat va masofa.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/models/marketplace/listing.dart';
import 'package:super_app/widgets/marketplace/listing_card.dart';
import 'package:super_app/widgets/marketplace/listing_grid.dart';

Listing _elon({
  int id = 1,
  String title = 'iPhone 13 Pro',
  double? priceUzs = 4500000,
  String currency = 'UZS',
  double? price = 4500000,
  bool negotiable = false,
  String condition = 'like_new',
  double? distance = 2.0,
}) {
  return Listing.fromJson({
    'id': id,
    'user_id': 7,
    'category_key': 'telefon',
    'title': title,
    'description': 'Yaxshi holatda',
    'price': price,
    'currency': currency,
    'price_uzs': priceUzs,
    'is_negotiable': negotiable,
    'condition': condition,
    'attributes': {'xotira': '256GB'},
    'address': 'Toshkent, Chilonzor',
    'status': 'active',
    'views': 12,
    'photos': <String>[],
    'distance_km': distance,
  });
}

Widget _qur(List<Listing> items) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(child: ListingGrid(listings: items)),
  ),
);

void main() {
  testWidgets('Grid 2 ustunli va har e\'lon uchun karta chiqadi', (
    tester,
  ) async {
    final items = List.generate(6, (i) => _elon(id: i + 1, title: 'Tel $i'));
    await tester.pumpWidget(_qur(items));
    await tester.pump();

    expect(find.byType(ListingCard), findsNWidgets(6));

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2, reason: 'chatда 2 ustun bo\'lishi kerak');
  });

  testWidgets('20 tadan ortiq e\'lon kelsa 20 tasi ko\'rsatiladi', (
    tester,
  ) async {
    // Chegara bo'lmasa chat butunlay kartalar bilan to'lib ketadi.
    final items = List.generate(35, (i) => _elon(id: i + 1));
    await tester.pumpWidget(_qur(items));
    await tester.pump();

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate = grid.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegate.childCount, kListingGridMax);
    expect(kListingGridMax, 20);
  });

  testWidgets('Kartada narx SO\'MDA, holat va masofa ko\'rinadi', (
    tester,
  ) async {
    await tester.pumpWidget(_qur([_elon()]));
    await tester.pump();

    expect(find.text('4 500 000 so\'m'), findsOneWidget);
    expect(find.textContaining('Ideal'), findsOneWidget);
    expect(find.textContaining('2.0 km'), findsOneWidget);
  });

  testWidgets('Dollarli e\'lon so\'mda ko\'rsatiladi, asli qavsda', (
    tester,
  ) async {
    // Foydalanuvchi qarori: xaridor chalg'imasin — asosiy narx so'mda.
    await tester.pumpWidget(
      _qur([_elon(price: 350, currency: 'USD', priceUzs: 4410000)]),
    );
    await tester.pump();

    expect(find.text('4 410 000 so\'m (350 \$)'), findsOneWidget);
  });

  testWidgets('"Kelishamiz" e\'lonida narx o\'rniga shu yozuv', (
    tester,
  ) async {
    await tester.pumpWidget(
      _qur([_elon(price: null, priceUzs: null, negotiable: true)]),
    );
    await tester.pump();

    expect(find.text('Kelishamiz'), findsOneWidget);
  });

  testWidgets('Bo\'sh ro\'yxatda grid umuman chizilmaydi', (tester) async {
    await tester.pumpWidget(_qur(const []));
    await tester.pump();

    expect(find.byType(GridView), findsNothing);
    expect(find.byType(ListingCard), findsNothing);
  });

  testWidgets('Karta bosilganda onTap chaqiriladi', (tester) async {
    Listing? bosilgan;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListingGrid(
            listings: [_elon(id: 42)],
            onTap: (l) => bosilgan = l,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(ListingCard));
    await tester.pump();

    expect(bosilgan?.id, 42);
  });
}
