import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/models/barber_shop.dart';

/// Model provayder kiritgan ish vaqtini HAQIQATAN ishlatishini tekshiradi.
/// Ilgari `isOpenNow()` qattiq 9–21 qaytarardi va `metadata.hours` e'tiborsiz
/// qolardi — ro'yxatda yopiq do'kon "Ochiq" deb ko'rinardi.
BarberShop _shop({Map<String, dynamic>? rawJson}) => BarberShop(
      id: '1',
      name: 'Test',
      address: 'Test',
      phoneNumber: '',
      rating: 4,
      reviewCount: 1,
      latitude: 41.31,
      longitude: 69.24,
      images: const [],
      services: const ['Erkaklar kesimi'],
      prices: const {'Erkaklar kesimi': 50000},
      barbers: const [],
      rawJson: rawJson,
    );

void main() {
  test('Ish vaqti kiritilmagan — standart 9:00-21:00', () {
    final s = _shop();
    expect(s.isOpenNow(DateTime(2026, 1, 1, 10)), isTrue);
    expect(s.isOpenNow(DateTime(2026, 1, 1, 22)), isFalse);
  });

  test('Ish vaqti kiritilgan — SHU ishlatiladi (standart emas)', () {
    final s = _shop(rawJson: const {
      'metadata': {'hours': '10:00-14:00'},
    });
    // Standart bo'yicha 15:00 ochiq bo'lardi, lekin do'kon 14 da yopiladi.
    expect(s.isOpenNow(DateTime(2026, 1, 1, 15)), isFalse,
        reason: 'kiritilgan ish vaqti ustunlik qilishi kerak');
    expect(s.isOpenNow(DateTime(2026, 1, 1, 11)), isTrue);
  });

  test('24/7 do\'kon tunda ham ochiq', () {
    final s = _shop(rawJson: const {
      'metadata': {'hours': '24/7'},
    });
    expect(s.isOpenNow(DateTime(2026, 1, 1, 3)), isTrue,
        reason: 'standart bo\'yicha 03:00 yopiq bo\'lardi');
  });

  test('Tushunarsiz ish vaqti — standartga qaytadi (crash yo\'q)', () {
    final s = _shop(rawJson: const {
      'metadata': {'hours': 'har kuni ochiq'},
    });
    expect(s.isOpenNow(DateTime(2026, 1, 1, 10)), isTrue);
    expect(s.isOpenNow(DateTime(2026, 1, 1, 23)), isFalse);
  });
}
