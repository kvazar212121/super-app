// Mening Dart kodim haqiqatan kompilyatsiya bo'ladimi va ishlaydimi.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/models/campaign.dart';
import 'package:super_app/screens/campaign_rating_screen.dart';
import 'package:super_app/widgets/campaign_banner.dart';

void main() {
  test('Campaign.fromJson backend javobini to\'g\'ri o\'qiydi', () {
    final c = Campaign.fromJson({
      'id': 7,
      'title': 'Eng yaxshi sartarosh',
      'description': 'test',
      'category_id': 3,
      'starts_at': '2026-09-01T00:00:00+00:00',
      'ends_at': '2026-09-30T23:59:59+00:00',
      'prize': "1-o'rin: 5 000 000",
      'status': 'running',
      'require_completed_order': true,
    });
    expect(c.id, 7);
    expect(c.requireCompletedOrder, isTrue);
    expect(c.status, CampaignStatus.running);
    expect(c.isRunning, isTrue);
    expect(c.categoryId, 3);
  });

  test('status noma\'lum bo\'lsa disabled', () {
    expect(campaignStatusFrom(null), CampaignStatus.disabled);
    expect(campaignStatusFrom('allaqanday'), CampaignStatus.disabled);
    expect(campaignStatusFrom('finished'), CampaignStatus.finished);
  });

  test('CampaignRanking.fromJson leaderboard javobini o\'qiydi', () {
    final r = CampaignRanking.fromJson({
      'id': 2,
      'name': 'Premium Cut',
      'address': 'Chilonzor',
      'votes': 118,
      'position': 2,
    });
    expect(r.providerId, 2);
    expect(r.votes, 118);
    expect(r.position, 2);
  });

  test('tugagan aksiyada remaining nol', () {
    final c = Campaign(
      id: 1,
      title: 'o\'tgan',
      startsAt: DateTime.now().subtract(const Duration(days: 30)),
      endsAt: DateTime.now().subtract(const Duration(days: 1)),
      status: CampaignStatus.finished,
    );
    expect(c.remaining, Duration.zero);
    expect(c.remainingLabel, 'Yakunlandi');
  });

  testWidgets('reyting ekrani chiziladi va ovoz tugmalari ko\'rinadi',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CampaignRatingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Sovrinli reyting'), findsOneWidget);
    expect(find.text('Style Barbershop'), findsOneWidget);
    // Test oynasi kichik: oxirgi qator ekrandan chiqib ketadi, shuning
    // uchun aniq son emas, "kamida bittasi bor" tekshiriladi.
    expect(find.widgetWithText(FilledButton, 'Ovoz'), findsWidgets);
  });

  testWidgets('ovoz berilgach boshqa tugmalar yo\'qoladi (1 kishi 1 ovoz)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CampaignRatingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Ovoz').first);
    await tester.pumpAndSettle();
    // Tasdiqlash oynasi
    expect(find.text('Ovoz berish'), findsOneWidget);
    await tester.tap(find.text('Ha, ovoz beraman'));
    await tester.pumpAndSettle();

    // Endi HECH QANDAY ovoz tugmasi qolmasligi kerak
    expect(find.widgetWithText(FilledButton, 'Ovoz'), findsNothing);
  });

  testWidgets('bekor qilinsa ovoz berilmaydi', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CampaignRatingScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Ovoz').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bekor qilish'));
    await tester.pumpAndSettle();

    // Tugmalar joyida qolishi kerak
    expect(find.widgetWithText(FilledButton, 'Ovoz'), findsWidgets);
  });

  testWidgets('bosh sahifa banneri chiziladi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CampaignBanner())),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
  });
}
