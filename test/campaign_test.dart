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

  // DIQQAT: reyting ekrani va banner endi HAQIQIY backendga boradi
  // (ApiService). Widget testida tarmoq yo'q, shuning uchun ular
  // "aksiya topilmadi" holatini ko'rsatishi kerak — ilova QULAMASLIGI
  // kerak. Ovoz berish mantig'i backend testida sinaladi
  // (tests/test_campaign_rating.py, 35 ta tekshiruv).

  testWidgets('reyting ekrani tarmoqsiz ham qulamaydi', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CampaignRatingScreen()));
    // Birinchi kadr: yuklanish indikatori
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    // Tarmoq yo'q -> xato yoki "aksiya yo'q" ko'rinadi, lekin ekran tirik
    expect(find.text('Sovrinli reyting'), findsOneWidget);
  });

  testWidgets('banner faol aksiya bo\'lmasa joy egallamaydi', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CampaignBanner())),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
    // Aksiya yo'q (tarmoq yo'q) -> banner ko'rinmasligi kerak,
    // lekin bosh sahifa buzilmasligi kerak
    expect(find.byIcon(Icons.emoji_events), findsNothing);
    expect(find.byType(CampaignBanner), findsOneWidget);
  });
}
