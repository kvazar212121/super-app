// E'lon MODAL oynasi — karta bosilganda ochiladigan ko'rinish.
//
// Foydalanuvchi talablari shu testda qo'riqlanadi:
//   • yangi ekran emas, MODAL ochiladi
//   • rasmlar aylanmasi (3-6 ta) suriladi
//   • sotuvchining TELEFON RAQAMI hech qayerda ko'rinmaydi
//   • aloqadan OLDIN firibgarlik ogohlantirishi chiqadi
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/models/marketplace/listing.dart';
import 'package:super_app/widgets/marketplace/listing_modal.dart';
import 'package:super_app/widgets/marketplace/photo_carousel.dart';
import 'package:super_app/widgets/marketplace/safety_warning_dialog.dart';

Listing _elon({List<String>? photos}) => Listing.fromJson({
  'id': 5,
  'user_id': 9,
  'category_key': 'telefon',
  'title': 'iPhone 13 Pro 256GB',
  'description': 'Ideal holatda, qutisi bor',
  'price': 4500000,
  'currency': 'UZS',
  'price_uzs': 4500000,
  'is_negotiable': false,
  'condition': 'like_new',
  'attributes': {'xotira': '256GB'},
  'address': 'Toshkent, Chilonzor',
  'status': 'active',
  'views': 34,
  'photos': photos ?? const ['/uploads/a.jpg', '/uploads/b.jpg', '/uploads/c.jpg'],
  'distance_km': 2.4,
});

Widget _qur(Listing listing) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showListingModal(context, listing),
        child: const Text('och'),
      ),
    ),
  ),
);

Future<void> _ochish(WidgetTester tester, Listing listing) async {
  await tester.pumpWidget(_qur(listing));
  await tester.tap(find.text('och'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(resetSafetyWarnings);

  testWidgets('Karta bosilganda MODAL ochiladi (yangi ekran emas)', (
    tester,
  ) async {
    await _ochish(tester, _elon());

    expect(find.byType(ListingModal), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
    // Tugma hamon daraxtda: ekran almashmagan, ustiga modal chiqqan.
    expect(find.text('och'), findsOneWidget);
  });

  testWidgets('Modalda to\'liq ma\'lumot va rasm aylanmasi bor', (
    tester,
  ) async {
    await _ochish(tester, _elon());

    expect(find.text('iPhone 13 Pro 256GB'), findsOneWidget);
    expect(find.text('4 500 000 so\'m'), findsOneWidget);
    expect(find.textContaining('Ideal holatda'), findsOneWidget);
    expect(find.text('xotira: 256GB'), findsOneWidget);
    expect(find.text('Toshkent, Chilonzor'), findsOneWidget);
    expect(find.byType(PhotoCarousel), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('Modalda telefon raqami YO\'Q, faqat ilova ichida aloqa', (
    tester,
  ) async {
    await _ochish(tester, _elon());

    // Loyihaning qat'iy qoidasi: raqam berilmaydi.
    expect(find.textContaining('+998'), findsNothing);
    expect(find.textContaining('Qo\'ng\'iroq raqami'), findsNothing);
    expect(find.text('Sotuvchiga yozish'), findsOneWidget);
  });

  testWidgets('Aloqadan OLDIN firibgarlik ogohlantirishi chiqadi', (
    tester,
  ) async {
    await _ochish(tester, _elon());

    await tester.tap(find.text('Sotuvchiga yozish'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('firibgar'), findsOneWidget);
    expect(find.text('Tushunarli'), findsOneWidget);
    expect(find.text('Shikoyat qilish'), findsOneWidget);
  });

  testWidgets('Shikoyat tugmasi sabab so\'raydi', (tester) async {
    await _ochish(tester, _elon());

    await tester.tap(find.text('Sotuvchiga yozish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shikoyat qilish'));
    await tester.pumpAndSettle();

    expect(find.text('Shikoyat'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Ogohlantirish bir e\'lon uchun ikki marta chiqmaydi', (
    tester,
  ) async {
    // Har bosishda chiqsa odam o'qimay yopadi va ma'nosi yo'qoladi.
    final listing = _elon();
    expect(
      await showSafetyWarningForTest(tester, listing.id),
      SafetyChoice.ok,
      reason: 'birinchi marta dialog ko\'rsatiladi',
    );
  });

  testWidgets('Rasmsiz e\'londa ham modal buzilmaydi', (tester) async {
    await _ochish(tester, _elon(photos: const []));

    expect(find.byType(ListingModal), findsOneWidget);
    expect(find.byType(PhotoCarousel), findsOneWidget);
  });
}

/// Ogohlantirishni ikkinchi marta chaqirib, dialogsiz `ok` qaytishini
/// tekshiradi (birinchi chaqiruv dialogni ko'rsatadi va yopiladi).
Future<SafetyChoice> showSafetyWarningForTest(
  WidgetTester tester,
  int listingId,
) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          ctx = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );

  final birinchi = showSafetyWarning(ctx, listingId);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Tushunarli'));
  await tester.pumpAndSettle();
  await birinchi;

  // Ikkinchi chaqiruv: dialog ko'rsatilmasdan darhol `ok`.
  final ikkinchi = await showSafetyWarning(ctx, listingId);
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsNothing);
  return ikkinchi;
}
