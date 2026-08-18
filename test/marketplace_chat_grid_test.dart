// Savdo natijasi CHAT EKRANIDA grid bo'lib chiqishini tekshiradi.
//
// `marketplace_grid_test.dart` gridning o'zini sinaydi. Bu yerda esa
// butun zanjir: backend yuborgan `{"type": "listing_grid", ...}`
// amali -> chat ekrani uni o'qiydi -> kartalar ko'rinadi. Ilgari
// chat faqat vertikal TUGMA chiqarardi; shu bog'lanish uzilsa
// foydalanuvchi hech qanday karta ko'rmaydi.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/providers/app_provider.dart';
import 'package:super_app/providers/auth_provider.dart';
import 'package:super_app/providers/saved_places_provider.dart';
import 'package:super_app/screens/chat_screen.dart';
import 'package:super_app/services/ai_service.dart';
import 'package:super_app/widgets/marketplace/listing_card.dart';
import 'package:super_app/widgets/marketplace/listing_grid.dart';
import 'dart:convert';

Map<String, dynamic> _elon(int id, String nom, double narx) => {
  'id': id,
  'user_id': 7,
  'category_key': 'telefon',
  'title': nom,
  'description': 'Tavsif',
  'price': narx,
  'currency': 'UZS',
  'price_uzs': narx,
  'is_negotiable': false,
  'condition': 'good',
  'attributes': <String, dynamic>{},
  'address': 'Toshkent',
  'status': 'active',
  'views': 3,
  'photos': <String>[],
  'distance_km': 1.5,
};

/// Chat tarixini diskka yozib qo'yamiz — ekran ochilganda uni
/// o'qiydi va amallarni (actions) tiklaydi.
void _tarix(List<Map<String, dynamic>> actions) {
  SharedPreferences.setMockInitialValues({
    'ai_chat_history_v2': jsonEncode([
      {'role': 'user', 'content': 'telefon olmoqchiman'},
      {'role': 'assistant', 'content': '3 ta e\'lon topdim', 'actions': actions},
    ]),
  });
}

Widget _qur() => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AppProvider()),
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => SavedPlacesProvider()),
  ],
  child: const MaterialApp(home: ChatScreen()),
);

/// Ekrandan chiqib, qolgan taymerlarni bo'shatadi.
Future<void> _yop(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 6));
}

void main() {
  // AiService — singleton va tarixni keshlaydi. Har testda yangi
  // tarix qo'yayotganimiz uchun keshni ochib yuboramiz.
  setUp(() => AiService().resetHistoryCache());

  testWidgets('listing_grid amali chatда KARTALAR qilib ko\'rsatiladi', (
    tester,
  ) async {
    _tarix([
      {
        'type': 'listing_grid',
        'listings': [
          _elon(1, 'iPhone 13', 4500000),
          _elon(2, 'Redmi 12', 1800000),
          _elon(3, 'Samsung A54', 3200000),
        ],
      },
    ]);

    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ListingGrid), findsOneWidget);
    expect(find.byType(ListingCard), findsNWidgets(3));
    expect(find.text('iPhone 13'), findsOneWidget);
    expect(find.text('4 500 000 so\'m'), findsOneWidget);

    await _yop(tester);
  });

  testWidgets('savdo amalisiz oddiy xabarda grid chiqmaydi', (tester) async {
    _tarix([]);

    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ListingGrid), findsNothing);

    await _yop(tester);
  });

  testWidgets('listings_changed amali "Mening e\'lonlarim" tugmasini beradi', (
    tester,
  ) async {
    _tarix([
      {'type': 'listings_changed', 'listing_id': 5},
    ]);

    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('e\'lonlarim'), findsOneWidget);

    await _yop(tester);
  });

  testWidgets('listing_detail amali e\'lon nomli tugma chiqaradi', (
    tester,
  ) async {
    _tarix([
      {'type': 'listing_detail', 'listing': _elon(9, 'MacBook Air', 9000000)},
    ]);

    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('MacBook Air'), findsOneWidget);

    await _yop(tester);
  });

  testWidgets('buzuq amal chatni yiqitmaydi', (tester) async {
    // Backend kutilmagan shakl yuborsa ham chat ishlashda davom etsin.
    _tarix([
      {'type': 'listing_grid'},
      {'type': 'listing_detail'},
    ]);

    await tester.pumpWidget(_qur());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.byType(ListingGrid), findsNothing);
    expect(tester.takeException(), isNull);

    await _yop(tester);
  });
}
