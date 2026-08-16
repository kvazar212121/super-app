import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:super_app/models/service_hub_kind.dart';
import 'package:super_app/providers/app_provider.dart';
import 'package:super_app/screens/service_hub/service_catalog_screen.dart';
import 'package:super_app/screens/service_hub/service_list_screen.dart';
import 'package:super_app/widgets/hub/provider_list_row.dart';
import 'package:super_app/widgets/hub/provider_map_preview_card.dart';

/// BUTUN NATIJA ustidan yakuniy tekshiruv.
///
/// Kech yaratilgan qat'iy tekshiruvlar (4 xil ekran kengligi, uzun matn,
/// tik rasm, 2x shrift) avval faqat SARTAROSH misolida ishlagan edi.
/// Bu yerda ular BARCHA 25 xizmat turi ustida takrorlanadi.
void main() {
  const accent = Color(0xFF2563EB);

  /// Eng yomon holatdagi ma'lumot: uzun nom, uzun manzil, ko'p sharh,
  /// uzoq masofa, uzun narx, ko'p teg.
  CatalogEntry worstCase(ServiceHubKind k) => CatalogEntry(
        id: '${k.name}_1',
        name: 'Juda uzun provayder nomi ${k.title} uchun sig\'maydi albatta',
        subtitle: 'Toshkent shahri Yunusobod tumani 4-kvartal 12-uy 3-podezd',
        rating: 4.9,
        reviewCount: 1234,
        priceLabel: "1 250 000 — 2 500 000 so'm",
        icon: k.icon,
        latitude: 41.31,
        longitude: 69.24,
        tags: const [
          'Birinchi uzun xizmat nomi',
          'Ikkinchi uzun xizmat nomi',
          'Uchinchi xizmat',
          'To\'rtinchi',
        ],
        onOpen: (_) {},
      );

  Widget wrap(Widget child) => ChangeNotifierProvider<AppProvider>(
        create: (_) => AppProvider(),
        child: MaterialApp(home: child),
      );

  /// Keng tarqalgan ekran kengliklari (dp).
  const widths = <String, ({double px, double dpr})>{
    '320dp': (px: 640, dpr: 2.0),
    '360dp': (px: 1080, dpr: 3.0),
    '393dp': (px: 1080, dpr: 440 / 160),
    '411dp': (px: 1080, dpr: 420 / 160),
  };

  group('BARCHA xizmatlar × BARCHA ekran kengliklari', () {
    for (final w in widths.entries) {
      testWidgets('${w.key} — 25 xizmatning hech birida overflow yo\'q',
          (tester) async {
        tester.view.physicalSize = Size(w.value.px, 2400);
        tester.view.devicePixelRatio = w.value.dpr;
        addTearDown(tester.view.reset);

        final broken = <String>[];
        for (final k in ServiceHubKind.values) {
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: ProviderListRow(
                entry: worstCase(k),
                accent: accent,
                distanceKmValue: 11185.6,
              ),
            ),
          ));
          await tester.pump();
          final e = tester.takeException();
          if (e != null) broken.add('${k.name}: $e');
        }
        expect(broken, isEmpty,
            reason: '${w.key} da buzilgan xizmatlar:\n${broken.join('\n')}');
      });
    }

    testWidgets('2x tizim shriftida ham 25 xizmat buzilmaydi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 420 / 160;
      addTearDown(tester.view.reset);

      final broken = <String>[];
      for (final k in ServiceHubKind.values) {
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2.0)),
            child: child!,
          ),
          home: Scaffold(
            body: ProviderListRow(
              entry: worstCase(k),
              accent: accent,
              distanceKmValue: 11185.6,
            ),
          ),
        ));
        await tester.pump();
        final e = tester.takeException();
        if (e != null) broken.add('${k.name}: $e');
      }
      expect(broken, isEmpty, reason: broken.join('\n'));
    });

    testWidgets('Tik rasm 25 xizmatning hech birida qatorni cho\'zmaydi',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      for (final k in ServiceHubKind.values) {
        // Rasmsiz balandlik
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ProviderListRow(
              entry: CatalogEntry(
                id: 'a', name: 'Test', subtitle: 'Manzil', rating: 4.5,
                reviewCount: 10, priceLabel: '20k+', icon: k.icon,
                latitude: 41.3, longitude: 69.2,
                tags: const ['Teg'], onOpen: (_) {},
              ),
              accent: accent,
              distanceKmValue: 1.2,
            ),
          ),
        ));
        await tester.pump();
        final h1 = tester.getRect(find.byType(ProviderListRow)).height;

        // Tik rasm bilan
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: ProviderListRow(
              entry: CatalogEntry(
                id: 'b', name: 'Test', subtitle: 'Manzil', rating: 4.5,
                reviewCount: 10, priceLabel: '20k+', icon: k.icon,
                latitude: 41.3, longitude: 69.2,
                tags: const ['Teg'],
                coverUrl: 'https://example.invalid/vertical_9x16.jpg',
                onOpen: (_) {},
              ),
              accent: accent,
              distanceKmValue: 1.2,
            ),
          ),
        ));
        await tester.pump();
        final h2 = tester.getRect(find.byType(ProviderListRow)).height;

        expect(h2, h1, reason: '${k.name}: rasm balandlikni o\'zgartirdi');
      }
    });

    testWidgets('Preview karta 25 xizmatda ham buzilmaydi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 420 / 160;
      addTearDown(tester.view.reset);

      final broken = <String>[];
      for (final k in ServiceHubKind.values) {
        await tester.pumpWidget(wrap(Scaffold(
          body: ProviderMapPreviewCard(
            entry: worstCase(k),
            accent: accent,
            distanceKmValue: 11185.6,
            durationMin: 9999,
            onClose: () {},
            onOrder: () {},
          ),
        )));
        await tester.pump();
        final e = tester.takeException();
        if (e != null) broken.add('${k.name}: $e');
      }
      expect(broken, isEmpty, reason: broken.join('\n'));
    });
  });

  group('Ro\'yxat ekrani — barcha xizmatlar', () {
    testWidgets('Har xizmat uchun ekran xatosiz ochiladi', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final broken = <String>[];
      for (final k in ServiceHubKind.values) {
        await tester.pumpWidget(wrap(ServiceListScreen(
          kind: k,
          accent: k.accent,
          entries: [worstCase(k)],
          categories: const ['Tur 1', 'Tur 2'],
          onCategorySelected: (_) {},
        )));
        await tester.pump();
        final e = tester.takeException();
        if (e != null) {
          broken.add('${k.name}: $e');
          continue;
        }
        // Asosiy elementlar joyida
        if (find.text('Xaritadan').evaluate().isEmpty) {
          broken.add('${k.name}: "Xaritadan" tugmasi yo\'q');
        }
        if (find.text('Saqlanganlar').evaluate().isEmpty) {
          broken.add('${k.name}: "Saqlanganlar" yo\'q');
        }
        if (find.text('Filtrlar').evaluate().isEmpty) {
          broken.add('${k.name}: "Filtrlar" yo\'q');
        }
      }
      expect(broken, isEmpty, reason: broken.join('\n'));
    });

    testWidgets('Bo\'sh ro\'yxat har xizmatda to\'g\'ri xabar beradi',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      for (final k in ServiceHubKind.values) {
        await tester.pumpWidget(wrap(ServiceListScreen(
          kind: k,
          accent: k.accent,
          entries: const [],
        )));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: k.name);
        expect(find.text('Hozircha provayder yo\'q'), findsOneWidget,
            reason: k.name);
      }
    });
  });

  group('Model butunligi — barcha xizmatlar', () {
    test('Har xizmatda nom, izoh, ikonka, kalit va narx bor', () {
      final problems = <String>[];
      for (final k in ServiceHubKind.values) {
        if (k.title.trim().isEmpty) problems.add('${k.name}: nomi bo\'sh');
        if (k.hubSubtitle.trim().isEmpty) problems.add('${k.name}: izohi bo\'sh');
        if (k.key.trim().isEmpty) problems.add('${k.name}: kaliti bo\'sh');
        if (k.variants.isEmpty) problems.add('${k.name}: narxlari yo\'q');
        for (final v in k.variants) {
          if (v.label.trim().isEmpty || v.basePrice <= 0) {
            problems.add('${k.name}: noto\'g\'ri narx "${v.label}"');
          }
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });

    test('Kalitlar noyob va enum nomlari takrorlanmaydi', () {
      final keys = ServiceHubKind.values.map((e) => e.key).toList();
      final names = ServiceHubKind.values.map((e) => e.name).toList();
      expect(keys.length, keys.toSet().length, reason: 'kalit takrorlangan');
      expect(names.length, names.toSet().length);
    });

    test('Olib tashlangan xizmatlar qaytib kelmagan', () {
      final names = ServiceHubKind.values.map((e) => e.name).toSet();
      for (final gone in ['konditsioner', 'kompUsta', 'yana']) {
        expect(names, isNot(contains(gone)), reason: '$gone qaytib kelgan');
      }
    });

    test('3D rasm yo\'llari to\'g\'ri kengaytmada', () {
      for (final k in ServiceHubKind.values) {
        final a = k.asset3d;
        if (a == null) continue;
        expect(a, startsWith('assets/images/services3d/'), reason: k.name);
        expect(
          a.endsWith('.jpg') || a.endsWith('.png'),
          isTrue,
          reason: '${k.name}: $a',
        );
      }
    });
  });
}
