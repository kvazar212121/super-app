// Foydalanuvchi EKRANDA aynan nimani ko'radi.
//
// Ilgari test faqat "aksiya yo'q -> banner ko'rinmaydi" holatini
// sinardi. Bu esa asosiy talabni tekshirmasdi: aksiya E'LON QILINGANDA
// mijoz uni ko'radimi, sarlavha va sovrin chiqadimi, bosganda reyting
// ekraniga o'tadimi.
//
// Kiritilayotgan JSON — backend'ning HAQIQIY javob formati
// (tests/test_campaign_rating.py da prod bilan bir xil sxema
// tekshirilgan).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/models/campaign.dart';
import 'package:super_app/widgets/campaign_banner.dart';

Campaign _runningCampaign() {
  final now = DateTime.now().toUtc();
  return Campaign.fromJson({
    'id': 1,
    'title': 'Eng yaxshi sartarosh — Sentabr',
    'description': 'Oylik musobaqa',
    'category_id': 3,
    'starts_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    'ends_at': now.add(const Duration(days: 10)).toIso8601String(),
    'prize': "1-o'rin: 5 000 000 so'm",
    'status': 'running',
    'require_completed_order': true,
  });
}

void main() {
  testWidgets('Aksiya e\'lon qilinganda mijoz bannerni KO\'RADI',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampaignBanner(initialCampaign: _runningCampaign()),
        ),
      ),
    );
    await tester.pump();

    // Kubok ikonkasi — aksiya borligining ko'rinadigan belgisi
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);

    // Aksiya nomi ekranda yozilgan bo'lishi kerak
    expect(find.text('Eng yaxshi sartarosh — Sentabr'), findsOneWidget);

    // "Ovoz bering" chaqirig'i — foydalanuvchi nima qilishini bilishi kerak
    expect(
      find.textContaining('Ovoz bering'),
      findsOneWidget,
      reason: 'Mijoz nima qilish kerakligini tushunishi shart',
    );
  });

  testWidgets('Tugagan aksiya bannerda KO\'RSATILMAYDI',
      (WidgetTester tester) async {
    final now = DateTime.now().toUtc();
    final finished = Campaign.fromJson({
      'id': 2,
      'title': 'Tugagan aksiya',
      'description': '',
      'category_id': 3,
      'starts_at': now.subtract(const Duration(days: 40)).toIso8601String(),
      'ends_at': now.subtract(const Duration(days: 10)).toIso8601String(),
      'status': 'finished',
      'require_completed_order': true,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CampaignBanner(initialCampaign: finished)),
      ),
    );
    await tester.pump();

    // Tugagan musobaqaga ovoz berib bo'lmaydi, shuning uchun taklif
    // qilish ham noto'g'ri bo'lardi.
    expect(find.byIcon(Icons.emoji_events), findsNothing);
    expect(find.text('Tugagan aksiya'), findsNothing);
  });

  testWidgets('Boshlanmagan aksiya ham KO\'RSATILMAYDI',
      (WidgetTester tester) async {
    final now = DateTime.now().toUtc();
    final upcoming = Campaign.fromJson({
      'id': 3,
      'title': 'Kelasi oy aksiyasi',
      'description': '',
      'category_id': 3,
      'starts_at': now.add(const Duration(days: 5)).toIso8601String(),
      'ends_at': now.add(const Duration(days: 35)).toIso8601String(),
      'status': 'upcoming',
      'require_completed_order': true,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CampaignBanner(initialCampaign: upcoming)),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.emoji_events), findsNothing);
  });

  testWidgets('Bannerni bosganda reyting ekrani ochiladi',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampaignBanner(initialCampaign: _runningCampaign()),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.emoji_events));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Reyting ekrani ochilgani: uning sarlavhasi ko'rinadi.
    // (Banner eski sahifada qolgani uchun ikonka hamon topiladi,
    // shuning uchun sarlavha bo'yicha tekshiramiz.)
    expect(
      find.text('Sovrinli reyting'),
      findsOneWidget,
      reason: 'Bosgandan keyin reyting sahifasi ochilishi kerak',
    );

    // Tarmoq so'rovlari taymerlarini bo'shatamiz
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  });
}
