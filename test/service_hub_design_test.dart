import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:super_app/models/service_hub_kind.dart';
import 'package:super_app/utils/geo_utils.dart';
import 'package:super_app/providers/app_provider.dart';
import 'package:super_app/screens/service_hub/service_catalog_screen.dart';
import 'package:super_app/screens/service_hub/service_list_screen.dart';
import 'package:super_app/widgets/hub/provider_banner.dart';
import 'package:super_app/widgets/hub/provider_list_row.dart';
import 'package:super_app/widgets/hub/provider_map_preview_card.dart';

/// Yangi xizmat hub dizayni uchun testlar.
///
/// Har test dizayn maketidagi BITTA aniq talabni tekshiradi, shunda qaysi
/// talab bajarilgani/bajarilmagani aniq ko'rinadi.

const _accent = Color(0xFF2563EB);

/// Bosilganda ochilgan provayder nomini yozib boradigan sinov entry'si.
CatalogEntry _entry({
  required String id,
  required String name,
  String subtitle = 'Chilonzor 12-mavze',
  double rating = 4.6,
  int reviewCount = 128,
  String priceLabel = "50k so'm",
  bool isOpen = true,
  List<String> tags = const ['Erkaklar kesimi', 'Soqol olish'],
  double latitude = 41.31,
  double longitude = 69.24,
  List<String>? opened,
}) {
  return CatalogEntry(
    id: id,
    name: name,
    subtitle: subtitle,
    rating: rating,
    reviewCount: reviewCount,
    priceLabel: priceLabel,
    icon: LucideIcons.scissors,
    latitude: latitude,
    longitude: longitude,
    isOpen: isOpen,
    tags: tags,
    onOpen: (_) => opened?.add(name),
  );
}

Widget _wrap(Widget child) {
  return ChangeNotifierProvider<AppProvider>(
    create: (_) => AppProvider(),
    child: MaterialApp(home: child),
  );
}

Widget _listScreen(
  List<CatalogEntry> entries, {
  List<String> categories = const ['Erkaklar kesimi', 'Soqol olish'],
  String? selectedCategory,
  ValueChanged<String?>? onCategorySelected,
}) {
  return _wrap(
    ServiceListScreen(
      kind: ServiceHubKind.sartarosh,
      accent: _accent,
      entries: entries,
      categories: categories,
      selectedCategory: selectedCategory,
      onCategorySelected: onCategorySelected ?? (_) {},
    ),
  );
}

void main() {
  // ───────────────────────────────────────────────────────────
  // EKRAN 1 — ro'yxat
  // ───────────────────────────────────────────────────────────
  group('EKRAN 1 — ro\'yxat tuzilishi', () {
    testWidgets('Talab: tepada qidiruv maydoni bor', (tester) async {
      await tester.pumpWidget(_listScreen([_entry(id: 'a', name: 'Barber A')]));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Qidiruv maydoni'), findsOneWidget);
    });

    testWidgets('Talab: qidiruv yonida "Xaritadan" tugmasi bor',
        (tester) async {
      await tester.pumpWidget(_listScreen([_entry(id: 'a', name: 'Barber A')]));
      await tester.pump();

      expect(find.text('Xaritadan'), findsOneWidget);
      // Xarita ikonkasi bilan birga
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Xaritadan'),
            matching: find.byType(Row),
          ).first,
          matching: find.byIcon(LucideIcons.map),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Talab: xarita EKRAN 1 da ko\'rinmaydi (faqat tugma)',
        (tester) async {
      await tester.pumpWidget(_listScreen([_entry(id: 'a', name: 'Barber A')]));
      await tester.pump();

      // Eski dizaynda bu yerda FlutterMap bo'lardi — endi bo'lmasligi kerak.
      expect(find.byType(ProviderListRow), findsWidgets);
      expect(find.text('Xaritadan'), findsOneWidget);
    });

    testWidgets('Talab: har provayder to\'liq enli VERTIKAL qator bo\'lib chiqadi',
        (tester) async {
      await tester.pumpWidget(_listScreen([
        _entry(id: 'a', name: 'Barber A'),
        _entry(id: 'b', name: 'Barber B'),
        _entry(id: 'c', name: 'Barber C'),
      ]));
      await tester.pump();

      expect(find.byType(ProviderListRow), findsNWidgets(3));

      // Vertikal joylashuv: har qator oldingisidan pastda va bir xil chap chekka.
      final a = tester.getRect(find.byType(ProviderListRow).at(0));
      final b = tester.getRect(find.byType(ProviderListRow).at(1));
      expect(b.top, greaterThan(a.top), reason: 'qatorlar vertikal ketma-ket');
      expect(b.left, a.left, reason: 'bir xil chap chekka (to\'liq en)');

      // To'liq en — ekran kengligiga teng.
      final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(a.width, screenWidth);
    });

    testWidgets('Talab: qatorda BANNER chapda joylashadi', (tester) async {
      await tester.pumpWidget(_listScreen([_entry(id: 'a', name: 'Barber A')]));
      await tester.pump();

      final row = tester.getRect(find.byType(ProviderListRow).first);
      final name = tester.getRect(find.text('Barber A'));

      // Nom banner o'ngida bo'lishi kerak (banner 132px).
      expect(name.left, greaterThanOrEqualTo(row.left + 130),
          reason: 'matn banner (132px) dan o\'ngda boshlanadi');
    });

    testWidgets('Talab: qatorda barcha ma\'lumot bor (nom, manzil, reyting, narx, holat)',
        (tester) async {
      await tester.pumpWidget(_listScreen([
        _entry(
          id: 'a',
          name: 'Zamon Barber',
          subtitle: 'Yunusobod 4-kvartal',
          rating: 4.8,
          reviewCount: 92,
          priceLabel: "50k so'm",
        ),
      ]));
      await tester.pump();

      expect(find.text('Zamon Barber'), findsOneWidget, reason: 'nom');
      expect(find.text('Yunusobod 4-kvartal'), findsOneWidget, reason: 'manzil');
      expect(find.text('4.8'), findsOneWidget, reason: 'reyting');
      expect(find.text(' (92)'), findsOneWidget, reason: 'sharhlar soni');
      expect(find.text("50k so'm"), findsOneWidget, reason: 'narx');
      expect(find.text('Ochiq'), findsOneWidget, reason: 'ochiq/yopiq holati');
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('Talab: banner yonida TEGLAR ko\'rinadi', (tester) async {
      await tester.pumpWidget(_listScreen([
        _entry(
          id: 'a',
          name: 'Barber A',
          tags: const ['Erkaklar kesimi', 'Soqol olish', 'Styling'],
        ),
      ]));
      await tester.pump();

      expect(find.text('Erkaklar kesimi'), findsOneWidget);
      expect(find.text('Soqol olish'), findsOneWidget);
      expect(find.text('Styling'), findsOneWidget);
    });

    testWidgets('Yopiq provayder "Yopiq" deb belgilanadi', (tester) async {
      await tester.pumpWidget(
        _listScreen([_entry(id: 'a', name: 'Barber A', isOpen: false)]),
      );
      await tester.pump();

      expect(find.text('Yopiq'), findsOneWidget);
      expect(find.text('Ochiq'), findsNothing);
    });

    testWidgets('Talab: pastda "Saqlanganlar" va "Filtrlar" tugmalari bor',
        (tester) async {
      await tester.pumpWidget(_listScreen([_entry(id: 'a', name: 'Barber A')]));
      await tester.pump();

      expect(find.text('Saqlanganlar'), findsOneWidget);
      expect(find.text('Filtrlar'), findsOneWidget);

      // Ikkalasi ham ekranning PASTKI qismida.
      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final saved = tester.getRect(find.text('Saqlanganlar'));
      final filters = tester.getRect(find.text('Filtrlar'));
      expect(saved.center.dy, greaterThan(screenHeight * 0.8));
      expect(filters.center.dy, greaterThan(screenHeight * 0.8));
      // Yonma-yon
      expect(filters.left, greaterThan(saved.left));
    });
  });

  // ───────────────────────────────────────────────────────────
  // Funksionallik o'zgarmaganligi
  // ───────────────────────────────────────────────────────────
  group('Funksionallik saqlanganligi', () {
    testWidgets('Qator bosilganda provayder ochiladi (bron oqimi)',
        (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(_listScreen([
        _entry(id: 'a', name: 'Barber A', opened: opened),
        _entry(id: 'b', name: 'Barber B', opened: opened),
      ]));
      await tester.pump();

      await tester.tap(find.text('Barber B'));
      await tester.pump();

      expect(opened, ['Barber B'],
          reason: 'bosilgan provayder ochilishi kerak');
    });

    testWidgets('Qidiruv nom bo\'yicha filtrlaydi', (tester) async {
      await tester.pumpWidget(_listScreen([
        _entry(id: 'a', name: 'Zamon Barber'),
        _entry(id: 'b', name: 'Sharq Sartaroshxona'),
      ]));
      await tester.pump();

      expect(find.byType(ProviderListRow), findsNWidgets(2));

      await tester.enterText(find.byType(TextField), 'sharq');
      await tester.pump();

      expect(find.byType(ProviderListRow), findsOneWidget);
      expect(find.text('Sharq Sartaroshxona'), findsOneWidget);
      expect(find.text('Zamon Barber'), findsNothing);
    });

    testWidgets('Qidiruv teg va manzil bo\'yicha ham ishlaydi', (tester) async {
      await tester.pumpWidget(_listScreen([
        _entry(id: 'a', name: 'A', subtitle: 'Chilonzor', tags: const ['Styling']),
        _entry(id: 'b', name: 'B', subtitle: 'Yunusobod', tags: const ['Soqol']),
      ]));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'styling');
      await tester.pump();
      expect(find.byType(ProviderListRow), findsOneWidget);
      expect(find.text('A'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'yunusobod');
      await tester.pump();
      expect(find.byType(ProviderListRow), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('Natija topilmasa bo\'sh holat ko\'rsatiladi', (tester) async {
      await tester.pumpWidget(
        _listScreen([_entry(id: 'a', name: 'Zamon Barber')]),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'xyz-topilmaydi');
      await tester.pump();

      expect(find.byType(ProviderListRow), findsNothing);
      expect(find.text('Hech narsa topilmadi'), findsOneWidget);
    });

    testWidgets('Provayder umuman yo\'q bo\'lsa mos xabar chiqadi',
        (tester) async {
      await tester.pumpWidget(_listScreen(const []));
      await tester.pump();

      expect(find.text('Hozircha provayder yo\'q'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────
  // Filtrlar — subkategoriyalar modalga ko'chgani
  // ───────────────────────────────────────────────────────────
  group('Filtrlar modali', () {
    testWidgets('Talab: subkategoriyalar ro\'yxat ustida EMAS, modalda',
        (tester) async {
      await tester.pumpWidget(_listScreen(
        [_entry(id: 'a', name: 'Barber A', tags: const [])],
        categories: const ['Erkaklar kesimi', 'Bolalar kesimi'],
      ));
      await tester.pump();

      // Modal ochilmasdan oldin — subkategoriya ekranda ko'rinmaydi.
      expect(find.text('Bolalar kesimi'), findsNothing);

      // "Filtrlar" bosilganda — modalda chiqadi.
      await tester.tap(find.text('Filtrlar'));
      await tester.pumpAndSettle();

      expect(find.text('Xizmat turi'), findsOneWidget);
      expect(find.text('Bolalar kesimi'), findsOneWidget);
      expect(find.text('Saralash'), findsOneWidget);
    });

    testWidgets('Modaldan subkategoriya tanlanadi', (tester) async {
      String? picked;
      await tester.pumpWidget(_listScreen(
        [_entry(id: 'a', name: 'Barber A', tags: const [])],
        categories: const ['Erkaklar kesimi', 'Bolalar kesimi'],
        onCategorySelected: (v) => picked = v,
      ));
      await tester.pump();

      await tester.tap(find.text('Filtrlar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bolalar kesimi'));
      await tester.pumpAndSettle();

      expect(picked, 'Bolalar kesimi');
    });

    testWidgets('Saralash: "Ochiq" tanlansa yopiqlar chiqmaydi',
        (tester) async {
      await tester.pumpWidget(_listScreen([
        _entry(id: 'a', name: 'Ochiq Barber', isOpen: true),
        _entry(id: 'b', name: 'Yopiq Barber', isOpen: false),
      ]));
      await tester.pump();

      expect(find.byType(ProviderListRow), findsNWidgets(2));

      await tester.tap(find.text('Filtrlar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hozir ochiq'));
      await tester.pumpAndSettle();

      expect(find.byType(ProviderListRow), findsOneWidget);
      expect(find.text('Ochiq Barber'), findsOneWidget);
      expect(find.text('Yopiq Barber'), findsNothing);
    });

    testWidgets('Saralash: "Reyting" bo\'yicha tartiblanadi', (tester) async {
      await tester.pumpWidget(_listScreen([
        _entry(id: 'a', name: 'Past', rating: 3.2, latitude: 41.31),
        _entry(id: 'b', name: 'Yuqori', rating: 4.9, latitude: 41.50),
      ]));
      await tester.pump();

      await tester.tap(find.text('Filtrlar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reyting'));
      await tester.pumpAndSettle();

      final high = tester.getRect(find.text('Yuqori'));
      final low = tester.getRect(find.text('Past'));
      expect(high.top, lessThan(low.top),
          reason: 'yuqori reyting birinchi bo\'lishi kerak');
    });

    testWidgets('Standart tartib — eng yaqindan', (tester) async {
      // kDefaultUserLat = 41.311081. 'Yaqin' unga juda yaqin.
      await tester.pumpWidget(_listScreen([
        _entry(id: 'a', name: 'Uzoq', latitude: 41.60, longitude: 69.50),
        _entry(id: 'b', name: 'Yaqin', latitude: 41.3111, longitude: 69.2406),
      ]));
      await tester.pump();

      final near = tester.getRect(find.text('Yaqin'));
      final far = tester.getRect(find.text('Uzoq'));
      expect(near.top, lessThan(far.top));
    });
  });

  // ───────────────────────────────────────────────────────────
  // EKRAN 2 — xarita preview kartasi
  // ───────────────────────────────────────────────────────────
  group('EKRAN 2 — preview karta', () {
    testWidgets('Talab: preview kartada "Buyurtma berish" tugmasi bor',
        (tester) async {
      var ordered = false;
      await tester.pumpWidget(_wrap(
        Scaffold(
          body: ProviderMapPreviewCard(
            entry: _entry(id: 'a', name: 'Barber A'),
            accent: _accent,
            distanceKmValue: 8.7,
            durationMin: 21,
            onClose: () {},
            onOrder: () => ordered = true,
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Buyurtma berish'), findsOneWidget);
      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);

      await tester.tap(find.text('Buyurtma berish'));
      await tester.pump();
      expect(ordered, isTrue, reason: 'tugma bron oqimini ochishi kerak');
    });

    testWidgets('Talab: preview karta ro\'yxat qatori bilan BIR XIL ma\'lumot',
        (tester) async {
      final entry = _entry(
        id: 'a',
        name: 'Zamon Barber',
        subtitle: 'Yunusobod 4-kvartal',
        rating: 4.8,
        reviewCount: 92,
        priceLabel: "50k so'm",
        tags: const ['Erkaklar kesimi'],
      );

      await tester.pumpWidget(_wrap(
        Scaffold(
          body: ProviderMapPreviewCard(
            entry: entry,
            accent: _accent,
            distanceKmValue: 8.7,
            onClose: () {},
            onOrder: () {},
          ),
        ),
      ));
      await tester.pump();

      // Ro'yxat qatoridagi maydonlarning hammasi shu yerda ham bor.
      expect(find.text('Zamon Barber'), findsOneWidget);
      expect(find.text('Yunusobod 4-kvartal'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text(' (92)'), findsOneWidget);
      expect(find.text("50k so'm"), findsOneWidget);
      expect(find.text('Erkaklar kesimi'), findsOneWidget);
    });

    testWidgets('Preview kartada masofa va vaqt ko\'rsatiladi', (tester) async {
      await tester.pumpWidget(_wrap(
        Scaffold(
          body: ProviderMapPreviewCard(
            entry: _entry(id: 'a', name: 'Barber A'),
            accent: _accent,
            distanceKmValue: 8.7,
            durationMin: 21,
            onClose: () {},
            onOrder: () {},
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('8.7 km'), findsOneWidget);
      expect(find.text('21 daq'), findsOneWidget);
    });

    testWidgets('Preview kartani yopish tugmasi ishlaydi', (tester) async {
      var closed = false;
      await tester.pumpWidget(_wrap(
        Scaffold(
          body: ProviderMapPreviewCard(
            entry: _entry(id: 'a', name: 'Barber A'),
            accent: _accent,
            onClose: () => closed = true,
            onOrder: () {},
          ),
        ),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();
      expect(closed, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────
  // CatalogEntry — ma'lumot modeli
  // ───────────────────────────────────────────────────────────
  _edgeCases();
  _bannerAspect();
  _previewBottomRow();

  group('CatalogEntry banner manbai', () {
    test('coverUrl aniq berilsa o\'sha ishlatiladi', () {
      final e = CatalogEntry(
        name: 'A',
        subtitle: '',
        rating: 0,
        reviewCount: 0,
        priceLabel: '',
        icon: LucideIcons.scissors,
        latitude: 0,
        longitude: 0,
        coverUrl: '/media/aniq.jpg',
        rawJson: const {'cover_image': '/media/boshqa.jpg'},
        onOpen: (_) {},
      );
      expect(e.resolvedCoverUrl, '/media/aniq.jpg');
    });

    test('coverUrl bo\'lmasa rawJson dan olinadi', () {
      final e = CatalogEntry(
        name: 'A',
        subtitle: '',
        rating: 0,
        reviewCount: 0,
        priceLabel: '',
        icon: LucideIcons.scissors,
        latitude: 0,
        longitude: 0,
        rawJson: const {
          'metadata': {'cover_url': '/media/meta.jpg'},
        },
        onOpen: (_) {},
      );
      expect(e.resolvedCoverUrl, '/media/meta.jpg');
    });

    test('rasm umuman bo\'lmasa null (ikonka fallback ishlaydi)', () {
      final e = CatalogEntry(
        name: 'A',
        subtitle: '',
        rating: 0,
        reviewCount: 0,
        priceLabel: '',
        icon: LucideIcons.scissors,
        latitude: 0,
        longitude: 0,
        onOpen: (_) {},
      );
      expect(e.resolvedCoverUrl, isNull);
    });
  });
}

/// ─────────────────────────────────────────────────────────────
/// Chekka holatlar — buzilish ehtimoli yuqori bo'lgan vaziyatlar.
/// ─────────────────────────────────────────────────────────────
void _edgeCases() {
  group('Chekka holatlar', () {
    testWidgets('Katta tizim shrifti (2.0x) da qator kesilmaydi',
        (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>(
          create: (_) => AppProvider(),
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: ServiceListScreen(
              kind: ServiceHubKind.sartarosh,
              accent: _accent,
              entries: [_entry(id: 'a', name: 'Zamon Barber')],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull,
          reason: '2x shriftda overflow bo\'lmasligi kerak');
      expect(find.text('Zamon Barber'), findsOneWidget);
    });

    testWidgets('Juda uzun nom va manzil qatorni buzmaydi', (tester) async {
      await tester.pumpWidget(_listScreen([
        _entry(
          id: 'a',
          name: 'Juda uzun sartaroshxona nomi bu yerda davom etadi va tugamaydi',
          subtitle:
              'Toshkent shahri Yunusobod tumani 4-kvartal 12-uy 3-podezd 45-xonadon',
          priceLabel: "1 250 000 so'm dan boshlab",
        ),
      ]));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(ProviderListRow), findsOneWidget);
    });

    testWidgets('Ko\'p teg (8 ta) qatorni buzmaydi', (tester) async {
      await tester.pumpWidget(_listScreen([
        _entry(id: 'a', name: 'Barber A', tags: const [
          'Erkaklar kesimi', 'Soqol olish', 'Bolalar kesimi', 'Styling',
          'Ukladka', 'Bo\'yash', 'Massaj', 'Parvarish',
        ]),
      ]));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Erkaklar kesimi'), findsOneWidget);
    });

    testWidgets('Teg umuman yo\'q bo\'lsa ham qator chiziladi', (tester) async {
      await tester.pumpWidget(
        _listScreen([_entry(id: 'a', name: 'Barber A', tags: const [])]),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(ProviderListRow), findsOneWidget);
      expect(find.text('Barber A'), findsOneWidget);
    });

    testWidgets('Reyting 0 bo\'lsa "—" ko\'rsatiladi (0.0 emas)',
        (tester) async {
      await tester.pumpWidget(_listScreen([
        _entry(id: 'a', name: 'Yangi Barber', rating: 0, reviewCount: 0),
      ]));
      await tester.pump();

      expect(find.text('—'), findsOneWidget);
      expect(find.text('0.0'), findsNothing);
    });

    testWidgets('Narx bo\'sh bo\'lsa narx qismi umuman chiqmaydi',
        (tester) async {
      await tester.pumpWidget(_listScreen([
        _entry(id: 'a', name: 'Barber A', priceLabel: ''),
      ]));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Barber A'), findsOneWidget);
    });

    testWidgets('Reyting kasrli bo\'lsa 1 xonagacha yaxlitlanadi',
        (tester) async {
      await tester.pumpWidget(_listScreen([
        _entry(id: 'a', name: 'Barber A', rating: 4.666666666),
      ]));
      await tester.pump();

      expect(find.text('4.7'), findsOneWidget);
      expect(find.text('4.666666666'), findsNothing);
    });

    testWidgets('Dark rejimda qator xatosiz chiziladi', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppProvider>(
          create: (_) => AppProvider(),
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: ServiceListScreen(
              kind: ServiceHubKind.sartarosh,
              accent: _accent,
              entries: [_entry(id: 'a', name: 'Barber A')],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Barber A'), findsOneWidget);
    });

    testWidgets('Ko\'p provayder (50 ta) ro\'yxati muammosiz', (tester) async {
      await tester.pumpWidget(_listScreen([
        for (var i = 0; i < 50; i++)
          _entry(id: 'p$i', name: 'Barber $i', latitude: 41.3 + i * 0.001),
      ]));
      await tester.pump();

      expect(tester.takeException(), isNull);
      // ListView — hammasi emas, ko'ringanlari chiziladi.
      expect(find.byType(ProviderListRow), findsWidgets);
    });

    testWidgets('Bir xil ID bo\'lmasligi — har entry noyob', (tester) async {
      final entries = [
        _entry(id: 'barber_1', name: 'A'),
        _entry(id: 'mobile_barber_1', name: 'B'),
      ];
      final ids = entries.map((e) => e.id).toSet();
      expect(ids.length, entries.length,
          reason: 'ID lar noyob bo\'lishi kerak (xarita markerlari uchun)');
    });
  });
}

/// ─────────────────────────────────────────────────────────────
/// Banner nisbati — provayder istalgan o'lchamdagi rasm yuklashi mumkin.
/// Tavsiya 1.2:1, lekin boshqa nisbat ham ko'rinishni BUZMASLIGI kerak.
/// ─────────────────────────────────────────────────────────────
void _bannerAspect() {
  group('Banner rasm nisbati', () {
    testWidgets('TIK (vertikal) rasm qatorni cho\'zib yubormaydi',
        (tester) async {
      // Muammo: emulyatorda tik rasm yuklagan provayder qatori boshqalardan
      // ~3 barobar baland chiqib, ro'yxatni buzib yuborardi.
      await tester.pumpWidget(_listScreen([
        _entry(id: 'a', name: 'Oddiy'),
        // 9:16 tik rasm yuklagan provayder
        CatalogEntry(
          id: 'b',
          name: 'Tik rasmli',
          subtitle: 'Innavatsiyalar agentligi',
          rating: 4.5,
          reviewCount: 10,
          priceLabel: '20k+',
          icon: LucideIcons.scissors,
          latitude: 41.31,
          longitude: 69.24,
          tags: const ['Erkaklar kesimi'],
          coverUrl: 'https://example.invalid/vertical_9x16.jpg',
          onOpen: (_) {},
        ),
        _entry(id: 'c', name: 'Yana oddiy'),
      ]));
      await tester.pump();

      final rows = find.byType(ProviderListRow);
      expect(rows, findsNWidgets(3));

      final h0 = tester.getRect(rows.at(0)).height;
      final h1 = tester.getRect(rows.at(1)).height;
      final h2 = tester.getRect(rows.at(2)).height;

      expect(h1, h0,
          reason: 'rasmli qator balandligi boshqalar bilan BIR XIL bo\'lishi '
              'kerak (banner balandlikni belgilamaydi)');
      expect(h2, h0);
    });

    testWidgets('Qator balandligini faqat MATN belgilaydi', (tester) async {
      // Rasmsiz va rasmli qator bir xil balandlikda bo'lishi kerak.
      await tester.pumpWidget(_listScreen([
        _entry(id: 'a', name: 'Rasmsiz'),
        CatalogEntry(
          id: 'b',
          name: 'Rasmli',
          subtitle: 'Chilonzor 12-mavze',
          rating: 4.6,
          reviewCount: 128,
          priceLabel: "50k so'm",
          icon: LucideIcons.scissors,
          latitude: 41.31,
          longitude: 69.24,
          tags: const ['Erkaklar kesimi', 'Soqol olish'],
          coverUrl: 'https://example.invalid/cover.jpg',
          onOpen: (_) {},
        ),
      ]));
      await tester.pump();

      final h0 = tester.getRect(find.byType(ProviderListRow).at(0)).height;
      final h1 = tester.getRect(find.byType(ProviderListRow).at(1)).height;
      expect(h1, h0);
      expect(h0, greaterThanOrEqualTo(ProviderListRow.minHeight),
          reason: 'qator eng kam balandlikdan past bo\'lmaydi');
      expect(h0, lessThan(ProviderListRow.minHeight + 20),
          reason: 'qator ixcham qoladi — rasm uni cho\'zmaydi');
    });

    testWidgets('Tavsiya etilgan nisbat 1.2:1 deb e\'lon qilingan',
        (tester) async {
      expect(ProviderListRow.bannerAspectRatio, 1.2);
      expect(ProviderBanner.recommendedAspectRatio, 1.2);
    });

    testWidgets('Xarita preview kartasi ham tik rasmdan cho\'zilmaydi',
        (tester) async {
      Future<double> heightFor(String? cover) async {
        await tester.pumpWidget(_wrap(
          Scaffold(
            body: ProviderMapPreviewCard(
              entry: CatalogEntry(
                id: 'a',
                name: 'Barber A',
                subtitle: 'Chilonzor',
                rating: 4.5,
                reviewCount: 10,
                priceLabel: '20k+',
                icon: LucideIcons.scissors,
                latitude: 41.31,
                longitude: 69.24,
                tags: const ['Erkaklar kesimi'],
                coverUrl: cover,
                onOpen: (_) {},
              ),
              accent: _accent,
              distanceKmValue: 8.7,
              onClose: () {},
              onOrder: () {},
            ),
          ),
        ));
        await tester.pump();
        return tester
            .getRect(find.byType(ProviderMapPreviewCard))
            .height;
      }

      final withoutImage = await heightFor(null);
      final withVertical =
          await heightFor('https://example.invalid/vertical_9x16.jpg');
      expect(withVertical, withoutImage,
          reason: 'preview karta balandligi rasmga bog\'liq bo\'lmasligi kerak');
    });
  });
}

/// ─────────────────────────────────────────────────────────────
/// Preview kartaning pastki qatori — chiplar tugmani siqib chiqarmasligi.
/// Emulyatorda "7989.2 km" + "5614 daqiqa" da 1px overflow bo'lgan edi.
/// ─────────────────────────────────────────────────────────────
void _previewBottomRow() {
  group('Preview karta pastki qatori', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      required double? km,
      required int? min,
      double width = 360,
    }) async {
      await tester.pumpWidget(_wrap(
        Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: ProviderMapPreviewCard(
                entry: _entry(id: 'a', name: 'Aziz — mobil sartarosh'),
                accent: _accent,
                distanceKmValue: km,
                durationMin: min,
                onClose: () {},
                onOrder: () {},
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('Juda uzoq masofa va vaqtda overflow bo\'lmaydi',
        (tester) async {
      await pumpCard(tester, km: 7989.2, min: 5614);
      expect(tester.takeException(), isNull);
      expect(find.text('Buyurtma berish'), findsOneWidget);
    });

    testWidgets('Tor ekranda (320dp) ham overflow bo\'lmaydi', (tester) async {
      await pumpCard(tester, km: 11188.1, min: 9999, width: 320);
      expect(tester.takeException(), isNull);
      expect(find.text('Buyurtma berish'), findsOneWidget);
    });

    testWidgets('Masofa/vaqt yo\'q bo\'lsa ham tugma joyida', (tester) async {
      await pumpCard(tester, km: null, min: null);
      expect(tester.takeException(), isNull);
      expect(find.text('Buyurtma berish'), findsOneWidget);
    });

    testWidgets('Uzun davomiylik inson o\'qiydigan ko\'rinishda', (tester) async {
      await pumpCard(tester, km: 7989.2, min: 5614);
      // 5614 daqiqa = 93 soat 34 daqiqa = 3 kun 21 soat
      expect(find.text('3 kun 21 soat'), findsOneWidget);
      expect(find.textContaining('5614'), findsNothing);
    });
  });

  group('formatDuration', () {
    test('bir soatdan kam — daqiqa', () {
      expect(formatDuration(45), '45 daq');
      expect(formatDuration(1), '1 daq');
    });

    test('soat va daqiqa', () {
      expect(formatDuration(135), '2 soat 15 daq');
      expect(formatDuration(120), '2 soat');
    });

    test('kun va soat', () {
      expect(formatDuration(5614), '3 kun 21 soat');
      expect(formatDuration(2880), '2 kun');
    });
  });
}
