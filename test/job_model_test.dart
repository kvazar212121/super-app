// Usta e'lon kartasida AYNAN nimani ko'radi.
//
// Bu ma'lumotlar ustaning ish olish qaroriga asos bo'ladi, shuning
// uchun ular ekranda haqiqatan chiqishi tekshiriladi: sarlavha, izoh,
// manzil, summa va nechta raqib taklif bergani.
//
// Kiritilayotgan JSON — backend'ning haqiqiy javob formati
// (tests/test_jobs_flutter_contract.py da har bir kalit haqiqiy HTTP
// javobi bilan solishtirilgan).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/models/job.dart';

void main() {
  test('JobPost backend javobini to\'liq o\'qiydi', () {
    final j = JobPost.fromJson({
      'id': 12,
      'user_id': 5,
      'category_id': 3,
      'title': 'Rozetka almashtirish',
      'description': 'Uchta rozetka kuyib qolgan',
      'photos': ['/uploads/jobs/a.jpg'],
      'address': 'Toshkent, Chilonzor 5',
      'budget': 200000.0,
      'needed_at': '2026-09-01T10:00:00+00:00',
      'status': 'open',
      'offers_count': 4,
      'assigned_provider_id': null,
      'created_at': '2026-08-17T10:00:00+00:00',
      'expires_at': '2026-08-24T10:00:00+00:00',
    });

    expect(j.id, 12);
    expect(j.title, 'Rozetka almashtirish');
    expect(j.address, 'Toshkent, Chilonzor 5');
    expect(j.budget, 200000.0);
    expect(j.offersCount, 4, reason: 'Usta raqiblar sonini ko\'rishi kerak');
    expect(j.assignedProviderId, isNull);
    expect(j.photos.length, 1);
  });

  test('budget null bo\'lsa "narx kelishiladi" holati', () {
    final j = JobPost.fromJson({
      'id': 13,
      'user_id': 5,
      'category_id': 3,
      'title': 'Simlarni tortish',
      'description': 'Katta ish',
      'photos': <String>[],
      'address': 'Toshkent',
      'budget': null,
      'needed_at': null,
      'status': 'open',
      'offers_count': 0,
      'assigned_provider_id': null,
      'created_at': '2026-08-17T10:00:00+00:00',
      'expires_at': null,
    });

    // Bu holatda ekranda "Narx kelishiladi" yozilishi kerak, ya'ni
    // budget null bo'lishi 0 ga aylanmasligi shart.
    expect(j.budget, isNull);
    expect(j.neededAt, isNull);
    expect(j.offersCount, 0);
  });

  test('JobOffer: chat uchun kerakli maydonlar o\'qiladi', () {
    final o = JobOffer.fromJson({
      'id': 9,
      'job_id': 12,
      'provider_id': 7,
      'provider_name': 'Usta Aziz',
      'provider_phone': '+998900000001',
      'provider_rating': 4.8,
      'provider_review_count': 15,
      'provider_owner_user_id': 42,
      'price': 180000.0,
      'duration_text': '2 soat',
      'message': 'Bugun kelaman',
      'status': 'pending',
      'created_at': '2026-08-17T11:00:00+00:00',
    });

    expect(o.providerName, 'Usta Aziz');
    expect(o.price, 180000.0);
    expect(o.durationText, '2 soat');
    // Bu maydonsiz "Yozish" tugmasi jimgina ishlamay qoladi
    expect(o.providerOwnerUserId, 42,
        reason: 'Ustaga xabar yozish uchun uning user_id si kerak');
  });

  test('provider_owner_user_id yo\'q bo\'lsa null (qulamaydi)', () {
    final o = JobOffer.fromJson({
      'id': 10,
      'job_id': 12,
      'provider_id': 7,
      'price': 100000.0,
      'status': 'pending',
      'created_at': '2026-08-17T11:00:00+00:00',
    });

    // Eski backend javobida bu maydon bo'lmasligi mumkin — ilova
    // qulamasligi kerak, shunchaki chat tugmasi ko'rsatilmaydi.
    expect(o.providerOwnerUserId, isNull);
    expect(o.providerName, isNull);
    expect(o.price, 100000.0);
  });
}
