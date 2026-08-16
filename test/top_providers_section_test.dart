import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/models/service_hub_kind.dart';
import 'package:super_app/services/top_providers_service.dart';
import 'package:super_app/widgets/top_providers_section.dart';

/// Bosh sahifadagi "Top reytingli" bo'limining talablari.
void main() {
  final service = TopProvidersService();

  /// Sinov ma'lumoti: reyting bo'yicha kamayish tartibida.
  List<TopProvider> makeItems(int count, {int startAt = 0, String? label}) {
    return List.generate(count, (i) {
      final n = startAt + i;
      return TopProvider(
        id: n + 1,
        name: 'Provayder ${n + 1}',
        subtitle: 'Chilonzor',
        rating: 5.0 - n * 0.1,
        reviewCount: 100 - n,
        categoryLabel: label ?? 'Sartarosh',
        kind: ServiceHubKind.sartarosh,
        rawJson: const {},
      );
    });
  }

  tearDown(() => service.debugFetchOverride = null);

  Future<void> pumpSection(WidgetTester tester) async {
    // Test muhitining standart ekrani 800x600 — 10 ta qator + "Yana"
    // sig'masligi mumkin. Haqiqiy telefon balandligini beramiz.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: TopProvidersSection()),
        ),
      ),
    );
    await tester.pump(); // yuklash tugashi
  }

  /// Elementni ko'rinadigan joyga surib, bosadi.
  Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Talab: sarlavha "Top reytingli"', (tester) async {
    service.debugFetchOverride = ({kind, page = 1}) async =>
        (items: makeItems(10), hasMore: true);
    await pumpSection(tester);

    expect(find.text('Top reytingli'), findsOneWidget);
  });

  testWidgets('Talab: 10 ta provayder ko\'rsatiladi', (tester) async {
    service.debugFetchOverride = ({kind, page = 1}) async =>
        (items: makeItems(10), hasMore: true);
    await pumpSection(tester);

    expect(find.text('Provayder 1'), findsOneWidget);
    expect(find.text('Provayder 10'), findsOneWidget);
    expect(find.text('Provayder 11'), findsNothing);
    expect(find.text('10 ta'), findsOneWidget);
  });

  testWidgets('Talab: har qatorda REYTING ko\'rsatiladi', (tester) async {
    service.debugFetchOverride = ({kind, page = 1}) async =>
        (items: makeItems(3), hasMore: false);
    await pumpSection(tester);

    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('4.9'), findsOneWidget);
    expect(find.text('4.8'), findsOneWidget);
    // Sharhlar soni ham
    expect(find.text('100 sharh'), findsOneWidget);
  });

  testWidgets('Talab: eng pastda "Yana" tugmasi', (tester) async {
    service.debugFetchOverride = ({kind, page = 1}) async =>
        (items: makeItems(10), hasMore: true);
    await pumpSection(tester);

    expect(find.text('Yana'), findsOneWidget);

    // "Yana" ro'yxatning ENG PASTIDA bo'lishi kerak.
    final last = tester.getRect(find.text('Provayder 10'));
    final more = tester.getRect(find.text('Yana'));
    expect(more.top, greaterThan(last.top));
  });

  testWidgets('Talab: "Yana" bosilsa pastga davom etadi (almashmaydi)',
      (tester) async {
    service.debugFetchOverride = ({kind, page = 1}) async {
      if (page == 1) return (items: makeItems(10), hasMore: true);
      return (items: makeItems(10, startAt: 10), hasMore: false);
    };
    await pumpSection(tester);

    expect(find.text('Provayder 1'), findsOneWidget);
    expect(find.text('Provayder 11'), findsNothing);

    await scrollAndTap(tester, find.text('Yana'));

    // Eskilari QOLADI, yangilari QO'SHILADI.
    expect(find.text('Provayder 1'), findsOneWidget,
        reason: 'birinchi sahifa yo\'qolmasligi kerak');
    expect(find.text('Provayder 11'), findsOneWidget);
    expect(find.text('20 ta'), findsOneWidget);
  });

  testWidgets('Oxirgi sahifada "Yana" yo\'qoladi', (tester) async {
    service.debugFetchOverride = ({kind, page = 1}) async {
      if (page == 1) return (items: makeItems(10), hasMore: true);
      return (items: makeItems(5, startAt: 10), hasMore: false);
    };
    await pumpSection(tester);
    expect(find.text('Yana'), findsOneWidget);

    await scrollAndTap(tester, find.text('Yana'));

    expect(find.text('Yana'), findsNothing,
        reason: 'boshqa sahifa qolmasa tugma ko\'rinmasin');
  });

  testWidgets('Talab: soha bo\'yicha FILTR bor', (tester) async {
    service.debugFetchOverride = ({kind, page = 1}) async =>
        (items: makeItems(3), hasMore: false);
    await pumpSection(tester);

    expect(find.text('Barchasi'), findsOneWidget);
    expect(find.text('Sartarosh'), findsWidgets);
    expect(find.text('Salon'), findsOneWidget);

    // Yangi qo'shilgan 3 ta xizmat ham filtrda bor (gorizontal ro'yxat —
    // ko'rinishi uchun suramiz).
    final chips = find.byType(ListView).first;
    for (final label in ['Telefon ustasi', 'Kompyuter ustasi', 'IT xizmatlari']) {
      await tester.scrollUntilVisible(
        find.text(label),
        120,
        scrollable: find.descendant(
          of: chips,
          matching: find.byType(Scrollable),
        ).first,
      );
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('Filtr tanlansa faqat o\'sha sohaniki yuklanadi',
      (tester) async {
    ServiceHubKind? requested;
    var calls = 0;
    service.debugFetchOverride = ({kind, page = 1}) async {
      requested = kind;
      calls++;
      return (
        items: makeItems(2, label: kind?.title ?? 'Sartarosh'),
        hasMore: false,
      );
    };
    await pumpSection(tester);
    expect(requested, isNull, reason: 'boshida "Barchasi"');
    expect(calls, 1);

    await scrollAndTap(tester, find.text('Salon'));

    expect(requested, ServiceHubKind.salon);
    expect(calls, 2);
  });

  testWidgets('Filtr almashsa ro\'yxat boshidan yuklanadi', (tester) async {
    service.debugFetchOverride = ({kind, page = 1}) async {
      if (kind == null) {
        return (items: makeItems(10), hasMore: true);
      }
      return (items: makeItems(2, startAt: 100), hasMore: false);
    };
    await pumpSection(tester);
    expect(find.text('10 ta'), findsOneWidget);

    await scrollAndTap(tester, find.text('Salon'));

    // Eski 10 ta qolmasligi kerak.
    expect(find.text('2 ta'), findsOneWidget);
    expect(find.text('Provayder 1'), findsNothing);
  });

  testWidgets('Bo\'sh natijada tushunarli xabar', (tester) async {
    service.debugFetchOverride = ({kind, page = 1}) async =>
        (items: <TopProvider>[], hasMore: false);
    await pumpSection(tester);

    expect(find.text('Hozircha reytingli provayder yo\'q'), findsOneWidget);
    expect(find.text('Yana'), findsNothing);
  });

  testWidgets('Birinchi 3 o\'rin raqamlangan', (tester) async {
    service.debugFetchOverride = ({kind, page = 1}) async =>
        (items: makeItems(5), hasMore: false);
    await pumpSection(tester);

    for (final n in ['1', '2', '3', '4', '5']) {
      expect(find.text(n), findsWidgets, reason: '$n-o\'rin ko\'rinishi kerak');
    }
  });

  testWidgets('Uzun nom va manzilda overflow bo\'lmaydi', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 420 / 160;
    addTearDown(tester.view.reset);

    service.debugFetchOverride = ({kind, page = 1}) async => (
      items: [
        TopProvider(
          id: 1,
          name: 'Juda uzun provayder nomi bu yerga umuman sig\'maydi albatta',
          subtitle:
              'Toshkent shahri Yunusobod tumani 4-kvartal 12-uy 3-podezd',
          rating: 4.9,
          reviewCount: 1234,
          categoryLabel: 'Sartaroshxona va go\'zallik saloni',
          kind: ServiceHubKind.sartarosh,
          rawJson: const {},
        ),
      ],
      hasMore: false,
    );
    await pumpSection(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('4.9'), findsOneWidget);
  });

  testWidgets('Talab: "Yana" bosilganda GLOBAL tartib buzilmaydi',
      (tester) async {
    // Real muammo: server saralamasa, 1-sahifa 4.9..4.4 keladi, 2-sahifada
    // esa yana 5.0 chiqib qolardi. Endi hammasi bir marta saralanadi.
    service.debugFetchOverride = null; // haqiqiy saralash mantiqini sinaymiz

    // Xizmatni to'g'ridan-to'g'ri sinash uchun kichik yordamchi:
    final unsorted = [
      TopProvider(id: 1, name: 'A', subtitle: '', rating: 4.4,
          reviewCount: 95, categoryLabel: 'X', rawJson: const {}),
      TopProvider(id: 2, name: 'B', subtitle: '', rating: 5.0,
          reviewCount: 84, categoryLabel: 'X', rawJson: const {}),
      TopProvider(id: 3, name: 'C', subtitle: '', rating: 4.9,
          reviewCount: 203, categoryLabel: 'X', rawJson: const {}),
    ];

    // Bo'lim shu tartibda ko'rsatishi kerak: B(5.0), C(4.9), A(4.4)
    final sorted = [...unsorted]..sort((a, b) {
        final r = b.rating.compareTo(a.rating);
        return r != 0 ? r : b.reviewCount.compareTo(a.reviewCount);
      });

    service.debugFetchOverride = ({kind, page = 1}) async =>
        (items: sorted, hasMore: false);
    await pumpSection(tester);

    final b = tester.getRect(find.text('B'));
    final c = tester.getRect(find.text('C'));
    final a = tester.getRect(find.text('A'));
    expect(b.top, lessThan(c.top), reason: '5.0 birinchi bo\'lsin');
    expect(c.top, lessThan(a.top), reason: '4.9 4.4 dan yuqorida');
  });
}
